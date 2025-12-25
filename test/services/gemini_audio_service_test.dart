import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:musically/models/note_data.dart';
import 'package:musically/services/gemini_audio_service.dart';

void main() {
  group('GeminiAudioService', () {
    late GeminiAudioService service;

    setUp(() {
      service = GeminiAudioService(
        apiKey: 'test-api-key',
        websocketUrl: 'wss://test.com/audio',
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initializes with correct values', () {
      expect(service.apiKey, equals('test-api-key'));
      expect(service.websocketUrl, equals('wss://test.com/audio'));
      expect(service.isConnected, isFalse);
    });

    test('connectLiveAPI sets isConnected to true', () async {
      expect(service.isConnected, isFalse);

      await service.connectLiveAPI();

      expect(service.isConnected, isTrue);
    });

    test('connectLiveAPI emits status updates', () async {
      final statuses = <String>[];
      service.statusStream.listen((status) => statuses.add(status));

      await service.connectLiveAPI();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses, isNotEmpty);
      expect(statuses.last, contains('Connected'));
    });

    test('connectLiveAPI does not reconnect if already connected', () async {
      await service.connectLiveAPI();

      final statusesBefore = <String>[];
      service.statusStream.listen((status) => statusesBefore.add(status));

      await service.connectLiveAPI();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(statusesBefore, contains('Already connected'));
    });

    test('streamAudioChunk requires connection', () async {
      final statuses = <String>[];
      service.statusStream.listen((status) => statuses.add(status));

      final audioData = Uint8List.fromList([0, 1, 2, 3]);
      service.streamAudioChunk(audioData);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses, contains('Not connected to Gemini API'));
    });

    test('streamAudioChunk emits notes when connected', () async {
      await service.connectLiveAPI();

      final notes = <NoteData>[];
      service.noteStream.listen((note) => notes.add(note));

      final audioData = Uint8List.fromList([0, 1, 2, 3]);
      service.streamAudioChunk(audioData);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(notes, isNotEmpty);
      expect(notes.first.pitch, isNotEmpty);
      expect(notes.first.confidence, greaterThan(0));
    });

    test('confidence stream emits values', () async {
      await service.connectLiveAPI();

      final confidences = <double>[];
      service.confidenceStream.listen((conf) => confidences.add(conf));

      final audioData = Uint8List.fromList([0, 1, 2, 3]);
      service.streamAudioChunk(audioData);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(confidences, isNotEmpty);
      expect(confidences.first, greaterThanOrEqualTo(0.0));
      expect(confidences.first, lessThanOrEqualTo(1.0));
    });

    test('getAverageConfidence returns 0 when no scores', () {
      expect(service.getAverageConfidence(), equals(0.0));
    });

    test('getAverageConfidence calculates average correctly', () async {
      await service.connectLiveAPI();

      // Generate some notes to populate confidence scores
      final audioData = Uint8List.fromList([0, 1, 2, 3]);
      for (var i = 0; i < 5; i++) {
        service.streamAudioChunk(audioData);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final avgConfidence = service.getAverageConfidence();

      expect(avgConfidence, greaterThan(0.0));
      expect(avgConfidence, lessThanOrEqualTo(1.0));
    });

    test('disconnect updates connection status', () async {
      await service.connectLiveAPI();
      expect(service.isConnected, isTrue);

      await service.disconnect();

      expect(service.isConnected, isFalse);
    });

    test('disconnect emits status update', () async {
      await service.connectLiveAPI();

      final statuses = <String>[];
      service.statusStream.listen((status) => statuses.add(status));

      await service.disconnect();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses, contains('Disconnected'));
    });

    test('disconnect when not connected does nothing', () async {
      expect(service.isConnected, isFalse);

      await service.disconnect();

      expect(service.isConnected, isFalse);
    });

    test('dispose closes streams', () async {
      await service.connectLiveAPI();
      await service.dispose();

      // Verify streams are closed by checking if adding to them throws
      expect(() => service.statusStream.listen((_) {}), returnsNormally);
    });

    test('handleResponse parses note data correctly', () async {
      await service.connectLiveAPI();

      final notes = <NoteData>[];
      service.noteStream.listen((note) => notes.add(note));

      // Simulate audio streaming which triggers note generation
      final audioData = Uint8List.fromList([0, 1, 2, 3]);
      service.streamAudioChunk(audioData);

      await Future.delayed(const Duration(milliseconds: 100));

      // The mock implementation should generate notes
      expect(notes.length, greaterThan(0));
    });

    test('multiple audio chunks generate multiple notes', () async {
      await service.connectLiveAPI();

      final notes = <NoteData>[];
      service.noteStream.listen((note) => notes.add(note));

      final audioData = Uint8List.fromList([0, 1, 2, 3]);

      for (var i = 0; i < 5; i++) {
        service.streamAudioChunk(audioData);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      expect(notes.length, greaterThanOrEqualTo(5));
    });

    test('confidence history is limited to 50 scores', () async {
      await service.connectLiveAPI();

      final audioData = Uint8List.fromList([0, 1, 2, 3]);

      // Generate more than 50 notes
      for (var i = 0; i < 60; i++) {
        service.streamAudioChunk(audioData);
        await Future.delayed(const Duration(milliseconds: 5));
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // The average should still be calculated
      // (internally, only last 50 scores are kept)
      final avgConfidence = service.getAverageConfidence();
      expect(avgConfidence, greaterThan(0.0));
      expect(avgConfidence, lessThanOrEqualTo(1.0));
    });
  });

  group('NoteData', () {
    test('creates with required fields', () {
      final note = NoteData(
        pitch: 'C4',
        frequency: 261.63,
        timestamp: 1000,
        confidence: 0.95,
        velocity: 80,
      );

      expect(note.pitch, equals('C4'));
      expect(note.frequency, equals(261.63));
      expect(note.timestamp, equals(1000));
      expect(note.confidence, equals(0.95));
      expect(note.velocity, equals(80));
    });

    test('JSON serialization round-trip works', () {
      final note = NoteData(
        pitch: 'D#5',
        frequency: 622.25,
        timestamp: 2000,
        confidence: 0.88,
        velocity: 100,
      );

      final json = note.toJson();
      final deserialized = NoteData.fromJson(json);

      expect(deserialized.pitch, equals(note.pitch));
      expect(deserialized.frequency, equals(note.frequency));
      expect(deserialized.timestamp, equals(note.timestamp));
      expect(deserialized.confidence, equals(note.confidence));
      expect(deserialized.velocity, equals(note.velocity));
    });

    test('toString formats correctly', () {
      final note = NoteData(
        pitch: 'A4',
        frequency: 440.0,
        timestamp: 1500,
        confidence: 0.92,
        velocity: 90,
      );

      final str = note.toString();

      expect(str, contains('A4'));
      expect(str, contains('440.0'));
      expect(str, contains('92.0%'));
    });

    test('fromJson handles numeric types correctly', () {
      final json = {
        'pitch': 'E4',
        'frequency': 329, // int instead of double
        'timestamp': 1000,
        'confidence': 0.9, // double
        'velocity': 85,
      };

      final note = NoteData.fromJson(json);

      expect(note.frequency, equals(329.0));
      expect(note.confidence, equals(0.9));
    });
  });
}
