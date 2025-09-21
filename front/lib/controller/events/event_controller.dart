import 'dart:convert';
import 'dart:io';
import 'package:front/model/events/event_model.dart';
import 'package:front/model/events/layout_model.dart';
import 'package:front/model/events/ticket_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;
import 'package:front/main.dart';
import 'package:image_picker/image_picker.dart';

class EventController {
  // Create Event with Layout (new method)
  static Future<http.Response> createEventWithLayout({
    required String eventName,
    required List<String> images,
    required String eventDescription,
    required DateTime eventDateTime,
    required String eventLocation,
    required LayoutModel layout,
    required double ticketPrice,
  }) {
    final token = HiveUtils.getData('token');
    final url = Uri.parse('$apiUrl/event/createEventWithLayout');
    return http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'eventName': eventName,
        'images': images,
        'eventDescription': eventDescription,
        'eventDateTime': eventDateTime.toIso8601String(),
        'eventLocation': eventLocation,
        'layout': layout.toJson(),
        'ticketPrice': ticketPrice,
      }),
    );
  }

  // Create Event with Tickets
  static Future<http.Response> createEventWithTickets({
    required String eventName,
    required List<String> images,
    required String eventDescription,
    required DateTime eventDateTime,
    required String eventLocation,
    required List<TicketModel> totalTickets,
    required double ticketPrice,
  }) {
    try {
      final token = HiveUtils.getData('token');
      final url = Uri.parse('$apiUrl/event/createEventWithTickets');
      return http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventName': eventName,
          'images': images,
          'eventDescription': eventDescription,
          'eventDateTime': eventDateTime.toIso8601String(),
          'eventLocation': eventLocation,
          'totalTickets': totalTickets,
          'ticketPrice': ticketPrice,
        }),
      );
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // save edited seat event
  static Future<http.Response> saveEditedSeatEvent({
    required String eventId,
    required String eventName,
    required List<String> images,
    required String eventDescription,
    required DateTime eventDateTime,
    required String eventLocation,
    required LayoutModel layout,
    required double ticketPrice,
  }) {
    final token = HiveUtils.getData('token');
    final url = Uri.parse('$apiUrl/event/updateEventWithLayout/$eventId');
    return http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'eventName': eventName,
        'images': images,
        'eventDescription': eventDescription,
        'eventDateTime': eventDateTime.toIso8601String(),
        'eventLocation': eventLocation,
        'layout': layout.toJson(),
        'ticketPrice': ticketPrice,
      }),
    );
  }

  //save edited ticket event
  static Future<http.Response> saveEditedTicketEvent({
    required String eventId,
    required String eventName,
    required List<String> images,
    required String eventDescription,
    required DateTime eventDateTime,
    required String eventLocation,
    required List<TicketModel> totalTickets,
    required double ticketPrice,
  }) {
    final token = HiveUtils.getData('token');
    final url = Uri.parse('$apiUrl/event/updateEventWithTickets/$eventId');
    return http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'eventName': eventName,
        'images': images,
        'eventDescription': eventDescription,
        'eventDateTime': eventDateTime.toIso8601String(),
        'eventLocation': eventLocation,
        'totalTickets': totalTickets.map((ticket) => ticket.toJson()).toList(),
        'ticketPrice': ticketPrice,
      }),
    );
  }

  //fetch all events
  static Future<List<EventModel>> fetchAllEvents() async {
    try {
      final url = Uri.parse('$apiUrl/event/getAllEvents');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body)['data'];
        return jsonData.map((event) => EventModel.fromJson(event)).toList();
      } else {
        throw Exception('Failed to fetch events: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      throw Exception('Failed to fetch events: $e $stackTrace');
    }
  }

  static Future<List<EventModel>> fetchEvents() async {
    final token = HiveUtils.getData('token');
    final url = Uri.parse('$apiUrl/event/getMyEvents');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body)['data'];
      return jsonData.map((event) => EventModel.fromJson(event)).toList();
    } else {
      throw Exception('Failed to fetch events: ${response.statusCode}');
    }
  }

  //delete event
  static Future<bool> deleteEvent(String eventId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/event/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Upload images to Cloudinary
  static Future<List<String>> uploadEventImages(List<XFile> imageFiles) async {
    List<String> uploadedImageUrls = [];

    for (XFile imageFile in imageFiles) {
      try {
        final result = await CloudinaryService.uploadFile(
          file: File(imageFile.path),
          fileType: 'eventImages',
        );
        if (result.containsKey('url')) {
          uploadedImageUrls.add(result['url']!);
        } else {
          print('Upload failed for ${imageFile.name}: No URL in response');
        }
      } catch (e) {
        print('Error uploading image ${imageFile.name}: $e');
      }
    }

    return uploadedImageUrls;
  }

  // Pick images from gallery or camera
  static Future<List<XFile>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      return images;
    } catch (e) {
      print('Error picking images: $e');
      return [];
    }
  }

  // Pick single image from camera
  static Future<XFile?> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  static Future uploadImagesToCloudinary(List<XFile> selectedImages) async {
    List<String> uploadedImageUrls = [];

    for (XFile imageFile in selectedImages) {
      try {
        final result = await CloudinaryService.uploadFile(
          file: File(imageFile.path),
          fileType: 'eventImages',
        );
        if (result.containsKey('url')) {
          uploadedImageUrls.add(result['url']!);
        } else {
          print('Upload failed for ${imageFile.name}: No URL in response');
        }
      } catch (e) {
        print('Error uploading image ${imageFile.name}: $e');
      }
    }

    return uploadedImageUrls;
  }

  static Future<bool> deleteImageFromCloudinary(String imageUrl) async {
    return await CloudinaryService.deleteFileByUrl(url: imageUrl);
  }
  
}
