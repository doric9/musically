import 'package:flutter_test/flutter_test.dart';
import 'package:musically/models/score.dart';

void main() {
  group('ScoreNote', () {
    test('creates note with required fields', () {
      const note = ScoreNote(
        pitch: 'C4',
        midiNumber: 60,
        startTime: 0,
        duration: 500,
        noteType: 'quarter',
      );

      expect(note.pitch, equals('C4'));
      expect(note.midiNumber, equals(60));
      expect(note.startTime, equals(0));
      expect(note.duration, equals(500));
      expect(note.noteType, equals('quarter'));
      expect(note.isDotted, isFalse);
    });

    test('octave getter returns correct value', () {
      const note = ScoreNote(
        pitch: 'C4',
        midiNumber: 60,
        startTime: 0,
        duration: 500,
        noteType: 'quarter',
      );

      expect(note.octave, equals(4));
    });

    test('noteName getter returns note without octave', () {
      const note = ScoreNote(
        pitch: 'C#5',
        midiNumber: 73,
        startTime: 0,
        duration: 500,
        noteType: 'quarter',
      );

      expect(note.noteName, equals('C#'));
    });

    test('matchesPitch returns true for exact match', () {
      const note = ScoreNote(
        pitch: 'C4',
        midiNumber: 60,
        startTime: 0,
        duration: 500,
        noteType: 'quarter',
      );

      expect(note.matchesPitch('C4'), isTrue);
      expect(note.matchesPitch('D4'), isFalse);
    });

    test('matchesPitch returns true for enharmonic equivalents', () {
      const note = ScoreNote(
        pitch: 'C#4',
        midiNumber: 61,
        startTime: 0,
        duration: 500,
        noteType: 'quarter',
      );

      expect(note.matchesPitch('Db4'), isTrue);
      expect(note.matchesPitch('C#4'), isTrue);
      expect(note.matchesPitch('D4'), isFalse);
    });

    test('JSON serialization round-trip works', () {
      const note = ScoreNote(
        pitch: 'D#5',
        midiNumber: 75,
        startTime: 100,
        duration: 250,
        noteType: 'eighth',
        isDotted: true,
        voice: 1,
        articulation: 'staccato',
      );

      final json = note.toJson();
      final deserialized = ScoreNote.fromJson(json);

      expect(deserialized.pitch, equals(note.pitch));
      expect(deserialized.midiNumber, equals(note.midiNumber));
      expect(deserialized.startTime, equals(note.startTime));
      expect(deserialized.duration, equals(note.duration));
      expect(deserialized.noteType, equals(note.noteType));
      expect(deserialized.isDotted, equals(note.isDotted));
      expect(deserialized.voice, equals(note.voice));
      expect(deserialized.articulation, equals(note.articulation));
    });
  });

  group('Measure', () {
    late List<ScoreNote> testNotes;

    setUp(() {
      testNotes = const [
        ScoreNote(
          pitch: 'C4',
          midiNumber: 60,
          startTime: 0,
          duration: 500,
          noteType: 'quarter',
        ),
        ScoreNote(
          pitch: 'E4',
          midiNumber: 64,
          startTime: 500,
          duration: 500,
          noteType: 'quarter',
        ),
      ];
    });

    test('creates measure with required fields', () {
      final measure = Measure(
        index: 0,
        startTime: 0,
        duration: 2000,
        notes: testNotes,
        timeSignature: '4/4',
      );

      expect(measure.index, equals(0));
      expect(measure.startTime, equals(0));
      expect(measure.duration, equals(2000));
      expect(measure.notes.length, equals(2));
      expect(measure.timeSignature, equals('4/4'));
    });

    test('getNote returns correct note by index', () {
      final measure = Measure(
        index: 0,
        startTime: 0,
        duration: 2000,
        notes: testNotes,
        timeSignature: '4/4',
      );

      final note = measure.getNote(0);
      expect(note, isNotNull);
      expect(note!.pitch, equals('C4'));

      expect(measure.getNote(1)!.pitch, equals('E4'));
      expect(measure.getNote(2), isNull);
      expect(measure.getNote(-1), isNull);
    });

    test('getNoteAtTime returns correct note', () {
      final measure = Measure(
        index: 0,
        startTime: 0,
        duration: 2000,
        notes: testNotes,
        timeSignature: '4/4',
      );

      final note1 = measure.getNoteAtTime(250);
      expect(note1, isNotNull);
      expect(note1!.pitch, equals('C4'));

      final note2 = measure.getNoteAtTime(750);
      expect(note2, isNotNull);
      expect(note2!.pitch, equals('E4'));

      final noNote = measure.getNoteAtTime(1500);
      expect(noNote, isNull);
    });

    test('JSON serialization round-trip works', () {
      final measure = Measure(
        index: 1,
        startTime: 2000,
        duration: 2000,
        notes: testNotes,
        timeSignature: '3/4',
        keySignature: 'G major',
        tempo: 120,
      );

      final json = measure.toJson();
      final deserialized = Measure.fromJson(json);

      expect(deserialized.index, equals(measure.index));
      expect(deserialized.startTime, equals(measure.startTime));
      expect(deserialized.duration, equals(measure.duration));
      expect(deserialized.notes.length, equals(measure.notes.length));
      expect(deserialized.timeSignature, equals(measure.timeSignature));
      expect(deserialized.keySignature, equals(measure.keySignature));
      expect(deserialized.tempo, equals(measure.tempo));
    });
  });

  group('Score', () {
    late Score testScore;

    setUp(() {
      final measures = [
        const Measure(
          index: 0,
          startTime: 0,
          duration: 2000,
          notes: [
            ScoreNote(
              pitch: 'C4',
              midiNumber: 60,
              startTime: 0,
              duration: 500,
              noteType: 'quarter',
            ),
            ScoreNote(
              pitch: 'D4',
              midiNumber: 62,
              startTime: 500,
              duration: 500,
              noteType: 'quarter',
            ),
          ],
          timeSignature: '4/4',
        ),
        const Measure(
          index: 1,
          startTime: 2000,
          duration: 2000,
          notes: [
            ScoreNote(
              pitch: 'E4',
              midiNumber: 64,
              startTime: 0,
              duration: 1000,
              noteType: 'half',
            ),
          ],
          timeSignature: '4/4',
        ),
      ];

      testScore = Score(
        id: 'test-1',
        title: 'Test Piece',
        composer: 'Test Composer',
        musicXmlContent: '<score></score>',
        measures: measures,
        totalDuration: 4000,
        description: 'A test piece',
        difficulty: 'Easy',
      );
    });

    test('creates score with required fields', () {
      expect(testScore.id, equals('test-1'));
      expect(testScore.title, equals('Test Piece'));
      expect(testScore.composer, equals('Test Composer'));
      expect(testScore.measures.length, equals(2));
      expect(testScore.totalDuration, equals(4000));
    });

    test('measureCount getter returns correct value', () {
      expect(testScore.measureCount, equals(2));
    });

    test('noteCount getter returns total notes', () {
      expect(testScore.noteCount, equals(3));
    });

    test('getMeasure returns correct measure by index', () {
      final measure = testScore.getMeasure(0);
      expect(measure, isNotNull);
      expect(measure!.index, equals(0));

      expect(testScore.getMeasure(1)!.index, equals(1));
      expect(testScore.getMeasure(2), isNull);
      expect(testScore.getMeasure(-1), isNull);
    });

    test('getMeasureAtTime returns correct measure', () {
      final measure1 = testScore.getMeasureAtTime(1000);
      expect(measure1, isNotNull);
      expect(measure1!.index, equals(0));

      final measure2 = testScore.getMeasureAtTime(2500);
      expect(measure2, isNotNull);
      expect(measure2!.index, equals(1));

      final noMeasure = testScore.getMeasureAtTime(5000);
      expect(noMeasure, isNull);
    });

    test('JSON serialization round-trip works', () {
      final json = testScore.toJson();
      final deserialized = Score.fromJson(json);

      expect(deserialized.id, equals(testScore.id));
      expect(deserialized.title, equals(testScore.title));
      expect(deserialized.composer, equals(testScore.composer));
      expect(deserialized.musicXmlContent, equals(testScore.musicXmlContent));
      expect(deserialized.measures.length, equals(testScore.measures.length));
      expect(deserialized.totalDuration, equals(testScore.totalDuration));
      expect(deserialized.description, equals(testScore.description));
      expect(deserialized.difficulty, equals(testScore.difficulty));
    });
  });

  group('ScorePosition', () {
    late Score testScore;

    setUp(() {
      final measures = [
        const Measure(
          index: 0,
          startTime: 0,
          duration: 2000,
          notes: [
            ScoreNote(
              pitch: 'C4',
              midiNumber: 60,
              startTime: 0,
              duration: 500,
              noteType: 'quarter',
            ),
            ScoreNote(
              pitch: 'D4',
              midiNumber: 62,
              startTime: 500,
              duration: 500,
              noteType: 'quarter',
            ),
          ],
          timeSignature: '4/4',
        ),
        const Measure(
          index: 1,
          startTime: 2000,
          duration: 2000,
          notes: [
            ScoreNote(
              pitch: 'E4',
              midiNumber: 64,
              startTime: 0,
              duration: 1000,
              noteType: 'half',
            ),
          ],
          timeSignature: '4/4',
        ),
      ];

      testScore = Score(
        id: 'test-1',
        title: 'Test Piece',
        composer: 'Test Composer',
        musicXmlContent: '<score></score>',
        measures: measures,
        totalDuration: 4000,
      );
    });

    test('initial creates position at start', () {
      final position = ScorePosition.initial();

      expect(position.measureIndex, equals(0));
      expect(position.noteIndex, equals(0));
      expect(position.timestamp, equals(0));
      expect(position.progress, equals(0.0));
    });

    test('fromIndices creates correct position', () {
      final position = ScorePosition.fromIndices(0, 1, testScore);

      expect(position.measureIndex, equals(0));
      expect(position.noteIndex, equals(1));
      expect(position.timestamp, equals(500));
      expect(position.progress, closeTo(0.125, 0.001));
    });

    test('advance moves to next note in same measure', () {
      final position = ScorePosition.fromIndices(0, 0, testScore);
      final advanced = position.advance(testScore);

      expect(advanced.measureIndex, equals(0));
      expect(advanced.noteIndex, equals(1));
    });

    test('advance moves to next measure', () {
      final position = ScorePosition.fromIndices(0, 1, testScore);
      final advanced = position.advance(testScore);

      expect(advanced.measureIndex, equals(1));
      expect(advanced.noteIndex, equals(0));
    });

    test('advance at end returns same position', () {
      final position = ScorePosition.fromIndices(1, 0, testScore);
      final advanced = position.advance(testScore);

      expect(advanced.measureIndex, equals(1));
      expect(advanced.noteIndex, equals(0));
    });

    test('rewind moves to previous note in same measure', () {
      final position = ScorePosition.fromIndices(0, 1, testScore);
      final rewound = position.rewind(testScore);

      expect(rewound.measureIndex, equals(0));
      expect(rewound.noteIndex, equals(0));
    });

    test('rewind moves to previous measure', () {
      final position = ScorePosition.fromIndices(1, 0, testScore);
      final rewound = position.rewind(testScore);

      expect(rewound.measureIndex, equals(0));
      expect(rewound.noteIndex, equals(1));
    });

    test('rewind at start returns same position', () {
      final position = ScorePosition.initial();
      final rewound = position.rewind(testScore);

      expect(rewound.measureIndex, equals(0));
      expect(rewound.noteIndex, equals(0));
    });

    test('isAtStart returns correct value', () {
      final start = ScorePosition.initial();
      expect(start.isAtStart(), isTrue);

      final notStart = ScorePosition.fromIndices(0, 1, testScore);
      expect(notStart.isAtStart(), isFalse);
    });

    test('isAtEnd returns correct value', () {
      final end = ScorePosition.fromIndices(1, 0, testScore);
      expect(end.isAtEnd(testScore), isTrue);

      final notEnd = ScorePosition.fromIndices(0, 0, testScore);
      expect(notEnd.isAtEnd(testScore), isFalse);
    });

    test('equality works correctly', () {
      final pos1 = ScorePosition.fromIndices(0, 1, testScore);
      final pos2 = ScorePosition.fromIndices(0, 1, testScore);
      final pos3 = ScorePosition.fromIndices(1, 0, testScore);

      expect(pos1 == pos2, isTrue);
      expect(pos1 == pos3, isFalse);
    });

    test('toString formats correctly', () {
      final position = ScorePosition.fromIndices(0, 1, testScore);
      final str = position.toString();

      expect(str, contains('measure: 0'));
      expect(str, contains('note: 1'));
      expect(str, contains('time: 500ms'));
      expect(str, contains('progress:'));
    });

    test('JSON serialization round-trip works', () {
      final position = ScorePosition.fromIndices(0, 1, testScore);
      final json = position.toJson();
      final deserialized = ScorePosition.fromJson(json);

      expect(deserialized.measureIndex, equals(position.measureIndex));
      expect(deserialized.noteIndex, equals(position.noteIndex));
      expect(deserialized.timestamp, equals(position.timestamp));
      expect(deserialized.progress, equals(position.progress));
    });
  });
}
