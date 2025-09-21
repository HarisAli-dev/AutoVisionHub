const cloudinary = require("../config/cloudinary");
const multer = require("multer");

// Configure multer for memory storage (no disk storage needed)
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 1000 * 1024 * 1024, // 1000MB limit
  },
}).single("file");

// Helper function to extract publicId from Cloudinary URL
const extractPublicIdFromUrl = (url) => {
  try {
    const urlParts = url.split("/");
    const uploadIndex = urlParts.findIndex((part) => part === "upload");
    if (uploadIndex === -1) return null;

    // Skip version (v1234567890) if present
    let startIndex = uploadIndex + 1;
    if (urlParts[startIndex] && urlParts[startIndex].startsWith("v")) {
      startIndex++;
    }

    // Get everything from folder to filename (without extension)
    const publicIdParts = urlParts.slice(startIndex);
    const lastPart = publicIdParts[publicIdParts.length - 1];
    publicIdParts[publicIdParts.length - 1] = lastPart.split(".")[0];

    return publicIdParts.join("/");
  } catch (error) {
    console.error("Error extracting publicId from URL:", error);
    return null;
  }
};

// Upload file to Cloudinary
exports.uploadFile = async (req, res) => {
  try {
    console.log("=== UPLOAD FILE REQUEST ===");
    console.log("Body:", req.body);
    console.log("File:", req.file ? "Present" : "Missing");

    // Handle multer upload
    upload(req, res, async (err) => {
      if (err) {
        console.error("Multer error:", err);
        return res.status(400).json({
          success: false,
          message: "File upload error: " + err.message,
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "No file provided",
        });
      }

      const { fileType } = req.body;

      if (!fileType) {
        return res.status(400).json({
          success: false,
          message: "File type is required",
        });
      }

      try {
        // Determine resource type based on file mime type and fileType
        let resourceType = "auto"; // Default to auto

        // Map fileType to Cloudinary resource types
        switch (fileType) {
          case "image":
            resourceType = "image";
            break;
          case "video":
            resourceType = "video";
            break;
          case "voice":
          case "audio":
            resourceType = "video"; // Audio files use 'video' resource type in Cloudinary
            break;
          case "file":
          default:
            resourceType = "raw"; // Documents and other files use 'raw'
            break;
        }

        // Generate unique public_id
        const userId = req.user.id || "anonymous";
        const timestamp = Date.now();
        const publicId = `${fileType}_${userId}_${timestamp}`;

        // Upload to Cloudinary using buffer
        const result = await new Promise((resolve, reject) => {
          cloudinary.uploader
            .upload_stream(
              {
                resource_type: resourceType,
                folder: fileType,
                public_id: publicId,
              },
              (error, result) => {
                if (error) {
                  reject(error);
                } else {
                  resolve(result);
                }
              }
            )
            .end(req.file.buffer);
        });

        console.log("Cloudinary upload successful:", result.public_id);

        // This is the thumbnail generation logic
        let thumbnailUrl = null;
        if (resourceType === "video") {
          try {
            thumbnailUrl = cloudinary.url(result.public_id, {
              resource_type: "video",
              secure: true,

              // ✅ ADD THESE TRANSFORMATIONS
              transformation: [
                { width: 400, crop: "fill" }, // Optional: set a width and crop
                { fetch_format: "jpg" }, // CRUCIAL: This changes the format to a JPG image
              ],
            });
          } catch (thumbnailError) {
            console.error("Error generating video thumbnail:", thumbnailError);
          }
        }

        const responseData = {
          url: result.secure_url,
          publicId: result.public_id,
          resourceType: result.resource_type,
          format: result.format,
          bytes: result.bytes,
        };

        // Add thumbnail URL if it was generated
        if (thumbnailUrl) {
          responseData.thumbnailUrl = thumbnailUrl;
        }

        res.status(201).json({
          success: true,
          message: "File uploaded successfully",
          data: responseData,
        });
      } catch (cloudinaryError) {
        console.error("Cloudinary upload error:", cloudinaryError);

        res.status(500).json({
          success: false,
          message: "Failed to upload file to cloud storage",
          error: cloudinaryError.message,
        });
      }
    });
  } catch (error) {
    console.error("Upload file error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

// Get file with optional transformations
exports.getFile = async (req, res) => {
  try {
    console.log("=== GET FILE REQUEST ===");
    console.log("Query params:", req.query);

    const {
      publicId,
      width,
      height,
      quality,
      format,
      resourceType,
      transformation,
    } = req.query;

    if (!publicId) {
      return res.status(400).json({
        success: false,
        message: "Public ID is required",
      });
    }

    // Build transformation parameters
    const transformations = [];

    // Handle custom transformation string (for video thumbnails)
    if (transformation) {
      transformations.push(transformation);
    }

    if (width || height) {
      let sizeTransform = "";
      if (width) sizeTransform += `w_${width}`;
      if (height) sizeTransform += (sizeTransform ? "," : "") + `h_${height}`;
      if (width && height) sizeTransform += ",c_fill"; // Default to fill crop when both dimensions provided
      transformations.push(sizeTransform);
    }

    if (quality && quality !== "auto") {
      transformations.push(`q_${quality}`);
    }

    if (format) {
      transformations.push(`f_${format}`);
    }

    // Generate URL with transformations
    const urlOptions = {
      secure: true,
      resource_type: resourceType || "auto",
    };

    if (transformations.length > 0) {
      urlOptions.transformation = transformations.join(",");
    }

    const url = cloudinary.url(publicId, urlOptions);

    console.log("Generated URL:", url);
    console.log("Resource type:", resourceType || "auto");
    console.log("Transformations:", transformations);

    res.status(200).json({
      success: true,
      data: {
        url: url,
        publicId: publicId,
        transformations: transformations,
        resourceType: resourceType || "auto",
      },
    });
  } catch (error) {
    console.error("Get file error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to get file",
      error: error.message,
    });
  }
};


// Delete file by URL
exports.deleteFileByUrl = async (req, res) => {
  try {
    console.log("=== DELETE FILE BY URL REQUEST ===");
    console.log("Body:", req.body);

    const { url } = req.body;

    if (!url) {
      return res.status(400).json({
        success: false,
        message: "URL is required",
      });
    }

    console.log("Deleting file with URL:", url);

    // Extract publicId from URL
    const publicId = extractPublicIdFromUrl(url);

    if (!publicId) {
      return res.status(400).json({
        success: false,
        message: "Could not extract public ID from URL",
      });
    }

    console.log("Extracted publicId:", publicId);

    // Use the delete by publicId function
    req.body = { publicId };
    return exports.deleteFile(req, res);
  } catch (error) {
    console.error("Delete file by URL error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

// Delete multiple files
exports.deleteMultipleFiles = async (req, res) => {
  try {
    console.log("=== DELETE MULTIPLE FILES REQUEST ===");
    console.log("Body:", req.body);

    const { publicIds } = req.body;

    if (!publicIds || !Array.isArray(publicIds) || publicIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Array of public IDs is required",
      });
    }

    console.log("Deleting files with publicIds:", publicIds);

    const deletePromises = publicIds.map(async (publicId) => {
      try {
        // Try different resource types
        let result = await cloudinary.uploader.destroy(publicId, {
          resource_type: "image",
        });

        if (result.result !== "ok") {
          result = await cloudinary.uploader.destroy(publicId, {
            resource_type: "video",
          });
        }

        if (result.result !== "ok") {
          result = await cloudinary.uploader.destroy(publicId, {
            resource_type: "raw",
          });
        }

        return {
          publicId: publicId,
          success: result.result === "ok" || result.result === "not found",
          result: result.result,
        };
      } catch (error) {
        console.error(`Error deleting ${publicId}:`, error);
        return {
          publicId: publicId,
          success: false,
          error: error.message,
        };
      }
    });

    const results = await Promise.all(deletePromises);

    console.log("Batch delete results:", results);

    res.status(200).json({
      success: true,
      message: "Batch delete completed",
      data: {
        results: results,
        totalProcessed: results.length,
        successCount: results.filter((r) => r.success).length,
        failedCount: results.filter((r) => !r.success).length,
      },
    });
  } catch (error) {
    console.error("Delete multiple files error:", error);
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};
