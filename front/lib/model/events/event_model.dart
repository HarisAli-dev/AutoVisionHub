import 'package:front/model/events/layout_model.dart';
import 'package:front/model/events/ticket_model.dart';
import 'package:front/model/users/user_model.dart';

class EventModel {
  String? id;
  List<String> images;
  String eventName;
  String eventDescription;
  DateTime eventDateTime;
  String eventLocation;
  String bookingType;
  double ticketPrice;
  User? createdBy;
  LayoutModel? layout; // Replace seatsList with layout
  List<TicketModel>? ticketList;
  final DateTime? createdAt;
  DateTime? updatedAt;

  EventModel({
    this.id,
    required this.images,
    required this.eventName,
    required this.eventDescription,
    required this.eventDateTime,
    required this.eventLocation,
    required this.bookingType,
    required this.ticketPrice,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.layout,
    this.ticketList,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      eventName: json['eventName'],
      eventDescription: json['eventDescription'],
      eventDateTime: DateTime.parse(json['eventDateTime']),
      eventLocation: json['eventLocation'],
      bookingType: json['bookingType'],
      ticketPrice: (json['ticketPrice'] as num).toDouble(),
      createdBy: json['createdBy'] != null
          ? User.fromJson(json['createdBy'])
          : null,

      layout: json['layout'] != null
          ? LayoutModel.fromJson(json['layout'])
          : null,
      ticketList: json['ticketList'] != null
          ? (json['ticketList'] as List)
                .map((ticketJson) => TicketModel.fromJson(ticketJson))
                .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventName': eventName,
    'eventDescription': eventDescription,
    'eventDateTime': eventDateTime.toIso8601String(),
    'eventLocation': eventLocation,
    'bookingType': bookingType,
    'images': images,
    'ticketPrice': ticketPrice,
    'createdBy': createdBy?.toJson(),
    'layout': layout?.toJson(),
    'ticketList': ticketList?.map((ticket) => ticket.toJson()).toList(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
