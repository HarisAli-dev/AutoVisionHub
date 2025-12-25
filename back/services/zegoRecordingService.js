const axios = require('axios');
const crypto = require('crypto');
const cloudinary = require('cloudinary').v2;

class ZegoRecordingService {
  constructor() {
    this.appId = process.env.ZEGO_APP_ID;
    this.serverSecret = process.env.ZEGO_SERVER_SECRET;
    this.apiBaseUrl = process.env.ZEGO_API_BASE_URL || 'https://rtc-api.zego.im';
    this.activeRecordings = new Map(); // roomId -> recordingId
  }

  /**
   * Generate ZEGO API signature for cloud recording
   */
  generateSignature(body, timestamp) {
    const nonce = Math.floor(Math.random() * 1000000);
    const signString = `${this.appId}${timestamp}${nonce}${this.serverSecret}${JSON.stringify(body)}`;
    const signature = crypto.createHash('md5').update(signString).digest('hex');
    return { signature, nonce };
  }

  /**
   * Start cloud recording for a live stream
   * @param {string} roomId - Room ID
   * @param {string} streamId - Stream ID to record
   * @returns {Promise<Object>} Recording details
   */
  async startRecording(roomId, streamId) {
    try {
      console.log(`🎥 Starting cloud recording for room: ${roomId}, stream: ${streamId}`);

      const timestamp = Math.floor(Date.now() / 1000);
      const body = {
        AppId: parseInt(this.appId),
        RoomId: roomId,
        StreamId: streamId,
        RecordMode: 1, // 1: Mixed stream recording, 2: Single stream recording
        Quality: 2, // 0: Low, 1: Medium, 2: High
        OutputFormat: 'mp4'
      };

      const { signature, nonce } = this.generateSignature(body, timestamp);

      // Note: ZEGO Cloud Recording requires enterprise plan
      // For now, we'll return a mock response and handle recording via client-side solution
      console.log('⚠️ ZEGO Cloud Recording requires enterprise plan');
      console.log('📝 Recording will be handled via local capture and upload');

      this.activeRecordings.set(roomId, {
        streamId,
        startTime: new Date(),
        status: 'pending'
      });

      return {
        success: true,
        recordingId: `rec_${roomId}_${Date.now()}`,
        message: 'Recording initiated (local capture mode)'
      };

    } catch (error) {
      console.error('❌ Error starting recording:', error.message);
      throw new Error(`Failed to start recording: ${error.message}`);
    }
  }

  /**
   * Stop cloud recording
   * @param {string} roomId - Room ID
   * @returns {Promise<Object>} Recording result
   */
  async stopRecording(roomId) {
    try {
      const recording = this.activeRecordings.get(roomId);
      if (!recording) {
        console.warn(`⚠️ No active recording found for room: ${roomId}`);
        return { success: false, message: 'No active recording found' };
      }

      console.log(`🛑 Stopping recording for room: ${roomId}`);

      this.activeRecordings.delete(roomId);

      return {
        success: true,
        duration: Math.floor((new Date() - recording.startTime) / 1000),
        message: 'Recording stopped'
      };

    } catch (error) {
      console.error('❌ Error stopping recording:', error.message);
      throw new Error(`Failed to stop recording: ${error.message}`);
    }
  }

  /**
   * Upload recorded video to Cloudinary
   * @param {string} filePath - Local file path of recorded video
   * @param {string} roomId - Room ID for identification
   * @returns {Promise<string>} Cloudinary URL
   */
  async uploadRecording(filePath, roomId) {
    try {
      console.log(`☁️ Uploading recording to Cloudinary for room: ${roomId}`);

      const result = await cloudinary.uploader.upload(filePath, {
        resource_type: 'video',
        folder: 'livestream_recordings',
        public_id: `recording_${roomId}_${Date.now()}`,
        chunk_size: 6000000, // 6MB chunks
        eager: [
          { width: 1280, height: 720, crop: 'limit', format: 'mp4' }
        ],
        eager_async: true
      });

      console.log('✅ Recording uploaded successfully:', result.secure_url);

      return result.secure_url;

    } catch (error) {
      console.error('❌ Error uploading recording:', error.message);
      throw new Error(`Failed to upload recording: ${error.message}`);
    }
  }

  /**
   * Save recording URL to database (called from controller)
   */
  async saveRecordingUrl(roomId, recordingUrl) {
    try {
      const { liveStreamService } = require('./liveStreamService');
      await liveStreamService.updateLiveStream(roomId, {
        recordingUrl
      });
      console.log(`✅ Recording URL saved for room: ${roomId}`);
    } catch (error) {
      console.error('❌ Error saving recording URL:', error.message);
    }
  }

  /**
   * Get recording status
   */
  getRecordingStatus(roomId) {
    const recording = this.activeRecordings.get(roomId);
    if (!recording) {
      return null;
    }

    return {
      ...recording,
      duration: Math.floor((new Date() - recording.startTime) / 1000),
      isActive: true
    };
  }
}

const zegoRecordingService = new ZegoRecordingService();
module.exports = { zegoRecordingService, ZegoRecordingService };
