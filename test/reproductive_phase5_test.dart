import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/reproductive_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/reproductive.dart';
import 'package:menomate_mobile/providers/data_providers.dart';
import 'package:menomate_mobile/providers/offline_mode_provider.dart';
import 'package:menomate_mobile/screens/aging_context_screen.dart';
import 'package:menomate_mobile/screens/fertility_log_screen.dart';
import 'package:menomate_mobile/screens/pregnancy_mode_screen.dart';
import 'package:menomate_mobile/widgets/fertility_estimate_card.dart';
import 'package:menomate_mobile/widgets/reproductive_home_block.dart';

import 'offline_fake_api.dart';

const _user = 'user-a';

AppDatabase _memoryDb() => AppDatabase.memory();

String _todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _isoOffset(int days) {
  final d = DateTime.now().add(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

FertilityEstimate _estimateWith({
  required FertilityEstimateStatus status,
  String? ovulation,
  String? windowStart,
  String? windowEnd,
}) {
  return FertilityEstimate(
    estimateDate: _todayIso(),
    status: status,
    estimatedOvulationDate: ovulation,
    fertileWindowStart: windowStart,
    fertileWindowEnd: windowEnd,
    evidenceSource: EstimateEvidenceSource.observed,
    method: 'fertility_v1',
    methodVersion: '1.0.0',
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AppDatabase db,
  required FakeApiService api,
  required Widget screen,
  bool offline = false,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final repo = ReproductiveRepository(db, api);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_user),
        isOfflineTrackingProvider.overrideWithValue(offline),
        appDatabaseProvider.overrideWithValue(db),
        reproductiveRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.6)),
        child: MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  // ---------------------------------------------------------- A. models
  group('A. API models: parsing, nulls, enums', () {
    test('observation JSON parses for all three types', () {
      final lh = FertilityObservation.fromJson({
        'id': 1,
        'user_id': 'u',
        'observation_date': '2026-09-01',
        'observation_type': 'lh_test',
        'lh_result': 'positive',
        'bbt_celsius': null,
        'mucus_category': null,
        'source': 'manual',
        'note': null,
      });
      expect(lh.observationType, ObservationTypes.lhTest);
      expect(lh.valueLabel, 'Positive');

      final bbt = FertilityObservation.fromJson({
        'id': 2,
        'user_id': 'u',
        'observation_date': '2026-09-01',
        'observation_type': 'bbt',
        'bbt_celsius': 36.6,
        'source': 'manual',
      });
      expect(bbt.bbtCelsius, 36.6);
      expect(bbt.valueLabel, contains('°C'));

      final mucus = FertilityObservation.fromJson({
        'id': 3,
        'user_id': 'u',
        'observation_date': '2026-09-01',
        'observation_type': 'cervical_mucus',
        'mucus_category': 'egg_white',
        'source': 'manual',
      });
      expect(mucus.valueLabel, 'Egg white');
    });

    test('estimate states parse; only AVAILABLE carries dates', () {
      final available = FertilityEstimate.fromJson({
        'estimate_date': '2026-09-10',
        'status': 'AVAILABLE',
        'estimated_ovulation_date': '2026-09-20',
        'fertile_window_start': '2026-09-15',
        'fertile_window_end': '2026-09-21',
        'evidence_source': 'OBSERVED',
        'method': 'fertility_v1',
        'method_version': '1.0.0',
      });
      expect(available.status, FertilityEstimateStatus.available);
      expect(available.hasDates, isTrue);

      // Defensive: dates smuggled in a non-AVAILABLE payload never render.
      final low = FertilityEstimate.fromJson({
        'estimate_date': '2026-09-10',
        'status': 'LOW_CONFIDENCE',
        'estimated_ovulation_date': '2026-09-20',
        'fertile_window_start': '2026-09-15',
        'fertile_window_end': '2026-09-21',
        'evidence_source': 'ESTIMATED',
        'method': 'fertility_v1',
        'method_version': '1.0.0',
      });
      expect(low.status, FertilityEstimateStatus.lowConfidence);
      expect(low.hasDates, isFalse);

      expect(
        parseEstimateStatus('SUPPRESSED'),
        FertilityEstimateStatus.suppressed,
      );
      expect(
        parseEstimateStatus('INSUFFICIENT_DATA'),
        FertilityEstimateStatus.insufficientData,
      );
      // Unknown wire values degrade to insufficient-data, never crash.
      expect(
        parseEstimateStatus('SOMETHING_NEW'),
        FertilityEstimateStatus.insufficientData,
      );
      expect(
        parseEstimateStatus(null),
        FertilityEstimateStatus.insufficientData,
      );

      // Missing disclaimer falls back to the fixed safety wording.
      expect(low.disclaimer, kFertilityEstimateDisclaimer);
    });

    test('provenance stays distinct: observed vs estimated vs confirmed', () {
      expect(parseEvidenceSource('OBSERVED'), EstimateEvidenceSource.observed);
      expect(
        parseEvidenceSource('ESTIMATED'),
        EstimateEvidenceSource.estimated,
      );
      expect(
        parseEvidenceSource('CLINICALLY_CONFIRMED'),
        EstimateEvidenceSource.clinicallyConfirmed,
      );
      expect(parseEvidenceSource(null), EstimateEvidenceSource.estimated);
      expect(parseEvidenceSource('NOPE'), EstimateEvidenceSource.estimated);
    });

    test('pregnancy JSON: inactive default, labels, provenance wording', () {
      final unset = PregnancyContext.fromJson(_user, {'is_active': false});
      expect(unset.isActive, isFalse);
      expect(unset.eddStatus, 'unavailable');
      expect(unset.hasDating, isFalse);
      expect(unset.hasGestationalAge, isFalse);

      final dated = PregnancyContext.fromJson(_user, {
        'is_active': true,
        'dating_source': 'clinician',
        'estimated_due_date': '2026-12-01',
        'edd_status': 'available',
        'edd_label': 'clinician_established_due_date',
        'dating_confidence': 'CLINICALLY_CONFIRMED',
        'gestational_age_total_days': 100,
        'gestational_age_weeks': 14,
        'gestational_age_days': 2,
        'days_until_due': 180,
        'as_of_date': '2026-09-10',
      });
      expect(dated.datingSourceLabel, 'Clinician-provided');
      expect(dated.eddLabelText, 'Clinician-established due date');
      // Technical codes convert to calm UI text, semantics preserved.
      expect(dated.provenanceLabel, 'Clinically confirmed');
      expect(dated.hasGestationalAge, isTrue);
      expect(dated.datingConfidence, 'CLINICALLY_CONFIRMED');
    });

    test('labels cover every backend vocabulary value', () {
      for (final v in ObservationTypes.all) {
        expect(kObservationTypeLabels[v], isNotNull, reason: v);
      }
      for (final v in LhResults.all) {
        expect(kLhResultLabels[v], isNotNull, reason: v);
      }
      for (final v in MucusCategories.all) {
        expect(kMucusCategoryLabels[v], isNotNull, reason: v);
      }
      for (final v in DatingSources.all) {
        expect(kDatingSourceLabels[v], isNotNull, reason: v);
      }
      expect(kEddLabelText['clinician_established_due_date'], isNotNull);
      expect(kEddLabelText['estimated_due_date'], isNotNull);
    });

    test('aging JSON: unset default, fixed user-declared provenance', () {
      final unset = AgingContext.fromJson(_user, {'has_context': false});
      expect(unset.hasContext, isFalse);
      expect(unset.notes, isNull);
      expect(unset.provenance, kAgingProvenanceUserDeclared);
      final set = AgingContext.fromJson(_user, {
        'has_context': true,
        'notes': 'noticing changes',
        'provenance': 'user_declared',
      });
      expect(set.hasContext, isTrue);
      expect(set.notes, 'noticing changes');
      // PUT payload carries notes only — no invented state vocabulary.
      expect(set.toPutJson().keys, ['notes']);
    });

    test('observation validation mirrors the backend contract', () {
      expect(
        validateObservationInput(
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.positive,
          observationDate: _isoOffset(-1),
        ),
        isNull,
      );
      expect(
        validateObservationInput(
          observationType: ObservationTypes.lhTest,
          observationDate: _isoOffset(-1),
        ),
        contains('LH test result'),
      );
      expect(
        validateObservationInput(
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.positive,
          bbtCelsius: 36.6,
          observationDate: _isoOffset(-1),
        ),
        contains('only the test result'),
      );
      expect(
        validateObservationInput(
          observationType: ObservationTypes.bbt,
          bbtCelsius: 34.9,
          observationDate: _isoOffset(-1),
        ),
        contains('35.00 and 42.00'),
      );
      expect(
        validateObservationInput(
          observationType: ObservationTypes.bbt,
          bbtCelsius: 36.6,
          observationDate: _isoOffset(1),
        ),
        contains('future'),
      );
      expect(
        validateObservationInput(
          observationType: ObservationTypes.cervicalMucus,
          mucusCategory: 'slippery',
          observationDate: _isoOffset(-1),
        ),
        contains('observed mucus category'),
      );
      expect(
        validateObservationInput(
          observationType: 'made_up',
          observationDate: _isoOffset(-1),
        ),
        contains('what you are recording'),
      );
    });

    test('pregnancy validation mirrors the backend joint rules', () {
      expect(
        validatePregnancyInput(
          datingSource: DatingSources.clinician,
          estimatedDueDate: _isoOffset(200),
        ),
        isNull,
      );
      expect(
        validatePregnancyInput(
          datingSource: DatingSources.unknown,
          estimatedDueDate: _isoOffset(200),
        ),
        contains('known source'),
      );
      expect(
        validatePregnancyInput(
          datingSource: DatingSources.ultrasound,
          lmpDate: _isoOffset(-50),
        ),
        contains('last-period dating'),
      );
      expect(
        validatePregnancyInput(
          datingSource: DatingSources.lmp,
          lmpDate: _isoOffset(1),
        ),
        contains('future'),
      );
      expect(
        validatePregnancyInput(
          datingSource: DatingSources.lmp,
          lmpDate: _isoOffset(-10),
          estimatedDueDate: _isoOffset(-20),
        ),
        contains('after the due date'),
      );
    });

    test('aging notes length mirrors the backend limit', () {
      expect(validateAgingNotes('short'), isNull);
      expect(validateAgingNotes(null), isNull);
      expect(
        validateAgingNotes('x' * (kAgingNoteMaxLength + 1)),
        contains('2000'),
      );
    });
  });

  // ---------------------------------------------------------- B. repository
  group('B. repository: requests, auth, errors, empty states', () {
    test('observation save succeeds online with a server id', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      final saved = await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-2),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.positive,
      );
      expect(saved, isA<Fresh<FertilityObservation>>());
      expect(saved.dataOrNull!.id, isNotNull);
      expect(api.createObservationCalls, 1);
      // No user identity travels in the payload: backend owns it.
      expect(api.lastObservationPayload!.containsKey('user_id'), isFalse);

      final listed = await repo.loadObservations(_user);
      expect(listed.dataOrNull!.length, 1);
    });

    test('offline saves stay pending and push on the next pass', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      final saved = await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-1),
        observationType: ObservationTypes.bbt,
        bbtCelsius: 36.6,
        localOnly: true,
      );
      expect(saved, isA<PendingSync<FertilityObservation>>());
      expect(api.createObservationCalls, 0);
      expect(await db.hasUnsyncedData(), isTrue);

      await repo.syncPending(_user);
      expect(api.createObservationCalls, 1);
      final listed = await repo.loadObservationsLocal(_user);
      expect(listed, isA<Fresh<List<FertilityObservation>>>());
      expect(await db.hasUnsyncedData(), isFalse);
    });

    test('observation update, type-mismatch rejection, date clash', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      final saved = await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-3),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.negative,
      );
      final localId = saved.dataOrNull!.localId!;

      final updated = await repo.updateObservation(
        _user,
        localId,
        lhResult: LhResults.positive,
      );
      expect(updated, isA<Fresh<FertilityObservation>>());
      expect(updated.dataOrNull!.lhResult, LhResults.positive);

      // Value fields must match the row's own type (backend 422 parity).
      await expectLater(
        repo.updateObservation(_user, localId, bbtCelsius: 36.6),
        throwsA(isA<ValidationError>()),
      );

      // A second LH row on another date, then a clashing move (409 parity).
      await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-4),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.negative,
      );
      await expectLater(
        repo.updateObservation(_user, localId, observationDate: _isoOffset(-4)),
        throwsA(isA<Conflict>()),
      );
    });

    test(
      'observation delete: unsynced drops, synced tombstones + pushes',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService();
        final repo = ReproductiveRepository(db, api);

        // Unsynced row disappears immediately with no API traffic.
        final pending = await repo.saveObservation(
          _user,
          observationDate: _isoOffset(-1),
          observationType: ObservationTypes.cervicalMucus,
          mucusCategory: MucusCategories.watery,
          localOnly: true,
        );
        await repo.deleteObservation(
          _user,
          pending.dataOrNull!.localId!,
          localOnly: true,
        );
        expect(
          await repo.loadObservationsLocal(_user),
          isA<NoData<List<FertilityObservation>>>(),
        );
        expect(api.deleteObservationCalls, 0);

        // Synced row becomes a pushed tombstone (idempotent DELETE).
        final synced = await repo.saveObservation(
          _user,
          observationDate: _isoOffset(-2),
          observationType: ObservationTypes.cervicalMucus,
          mucusCategory: MucusCategories.creamy,
        );
        await repo.deleteObservation(_user, synced.dataOrNull!.localId!);
        expect(api.deleteObservationCalls, 1);
        expect(api.serverObservations, isEmpty);
        expect(
          await repo.loadObservationsLocal(_user),
          isA<NoData<List<FertilityObservation>>>(),
        );
      },
    );

    test(
      're-saving the same date+type overwrites (upsert, no duplicate)',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService();
        final repo = ReproductiveRepository(db, api);

        await repo.saveObservation(
          _user,
          observationDate: _isoOffset(-1),
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.negative,
        );
        await repo.saveObservation(
          _user,
          observationDate: _isoOffset(-1),
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.positive,
        );
        expect(api.serverObservations.length, 1);
        expect(api.serverObservations.single.lhResult, LhResults.positive);
        final listed = await repo.loadObservationsLocal(_user);
        expect(listed.dataOrNull!.length, 1);
        expect(listed.dataOrNull!.single.lhResult, LhResults.positive);
      },
    );

    test('future observation dates rejected before any write', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await expectLater(
        repo.saveObservation(
          _user,
          observationDate: _isoOffset(1),
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.positive,
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(api.createObservationCalls, 0);
      expect(
        await repo.loadObservationsLocal(_user),
        isA<NoData<List<FertilityObservation>>>(),
      );
    });

    test(
      'estimate fetch succeeds; offline is Unavailable, never stale',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService()
          ..cannedEstimate = _estimateWith(
            status: FertilityEstimateStatus.available,
            ovulation: _isoOffset(5),
            windowStart: _isoOffset(0),
            windowEnd: _isoOffset(6),
          );
        final repo = ReproductiveRepository(db, api);

        final loaded = await repo.loadEstimate();
        expect(loaded, isA<Fresh<FertilityEstimate?>>());
        expect(loaded.dataOrNull!.hasDates, isTrue);

        expect(await repo.loadEstimateLocal(), isA<Unavailable>());

        api.offline = true;
        expect(await repo.loadEstimate(), isA<Unavailable>());
      },
    );

    test('auth failures are rethrown, never swallowed', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = _AuthFailingFake();
      final repo = ReproductiveRepository(db, api);
      await expectLater(repo.loadPregnancy(_user), throwsA(isA<AuthFailure>()));
      await expectLater(repo.loadEstimate(), throwsA(isA<AuthFailure>()));
    });

    test('pregnancy PUT round-trips; payload carries no user_id', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      // Never entered: inactive unset default (never a 404, never NoData).
      final initial = await repo.loadPregnancy(_user);
      expect(initial, isA<Fresh<PregnancyContext?>>());
      expect(initial.dataOrNull!.isActive, isFalse);

      final saved = await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.ultrasound,
          estimatedDueDate: _isoOffset(200),
        ),
      );
      expect(saved, isA<Fresh<PregnancyContext>>());
      expect(saved.dataOrNull!.isActive, isTrue);
      expect(api.lastPregnancyPutPayload!.containsKey('user_id'), isFalse);
      expect(api.putPregnancyCalls, 1);
    });

    test('pregnancy 409 downgrade surfaces hierarchy guidance', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.clinician,
          estimatedDueDate: _isoOffset(200),
        ),
      );
      final conflicted = await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.lmp,
          estimatedDueDate: _isoOffset(210),
          lmpDate: _isoOffset(-70),
        ),
      );
      expect(conflicted, isA<ConflictState<PregnancyContext>>());
      final message = (conflicted as ConflictState).message;
      expect(message, contains('provenance'));
      // Conflicting row trips the unsynced guard until resolved.
      expect(await db.hasUnsyncedData(), isTrue);
    });

    test('pregnancy deactivation retains history; erase removes', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.ultrasound,
          estimatedDueDate: _isoOffset(190),
        ),
      );
      final paused = await repo.deactivatePregnancy(_user);
      expect(paused.dataOrNull!.isActive, isFalse);
      expect(paused.dataOrNull!.estimatedDueDate, _isoOffset(190));

      await repo.deletePregnancy(_user);
      expect(api.serverPregnancy, isNull);
      expect(await repo.loadPregnancyLocal(_user), isA<NoData>());
    });

    test('aging save, verbatim notes, and clear path', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      expect(await repo.loadAgingLocal(_user), isA<NoData<AgingContext?>>());
      final saved = await repo.saveAging(_user, '  noticing  changes\nkept  ');
      expect(saved, isA<Fresh<AgingContext>>());
      expect(saved.dataOrNull!.hasContext, isTrue);
      expect(saved.dataOrNull!.notes, 'noticing  changes\nkept');
      expect(saved.dataOrNull!.provenance, kAgingProvenanceUserDeclared);

      final cleared = await repo.saveAging(_user, null);
      expect(cleared.dataOrNull!.hasContext, isFalse);
      expect(api.serverAging!.notes, isNull);
    });

    test(
      'empty states: observations NoData, singletons honest defaults',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService();
        final repo = ReproductiveRepository(db, api);

        expect(
          await repo.loadObservations(_user),
          isA<NoData<List<FertilityObservation>>>(),
        );
        final pregnancy = await repo.loadPregnancy(_user);
        expect(pregnancy.dataOrNull!.isActive, isFalse);
        final aging = await repo.loadAging(_user);
        expect(aging.dataOrNull!.hasContext, isFalse);
      },
    );

    test('reproductive work never touches prediction endpoints', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-1),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.negative,
      );
      await repo.savePregnancyPut(
        _user,
        PregnancyContext(userId: _user, isActive: true),
      );
      await repo.saveAging(_user, 'note');
      await repo.loadObservations(_user);
      await repo.loadPregnancy(_user);
      await repo.loadAging(_user);
      await repo.loadEstimate();
      await repo.syncPending(_user);

      expect(api.fetchCurrentCycleCalls, 0);
    });
  });

  // ---------------------------------------------------------- C. fertility UI
  group('C. fertility estimate presentation', () {
    Future<void> pumpCard(
      WidgetTester tester,
      DataState<FertilityEstimate?> state,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(),
            child: MaterialApp(
              home: Scaffold(body: FertilityEstimateCard(state: state)),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('AVAILABLE shows dates, estimate wording, disclaimer', (
      tester,
    ) async {
      final ovulation = _isoOffset(5);
      await pumpCard(
        tester,
        Fresh<FertilityEstimate?>(
          _estimateWith(
            status: FertilityEstimateStatus.available,
            ovulation: ovulation,
            windowStart: _isoOffset(0),
            windowEnd: _isoOffset(6),
          ),
        ),
      );
      expect(find.text('Estimated fertile window'), findsOneWidget);
      expect(find.textContaining('Estimated ovulation day'), findsOneWidget);
      expect(
        find.textContaining('can\u2019t confirm ovulation'),
        findsOneWidget,
      );
      // Screen-reader label carries the same estimated dates.
      expect(
        find.bySemanticsLabel(
          RegExp('Estimated fertile window', caseSensitive: false),
        ),
        findsWidgets,
      );
    });

    testWidgets('LOW_CONFIDENCE shows no dates and cautious wording', (
      tester,
    ) async {
      await pumpCard(
        tester,
        Fresh<FertilityEstimate?>(
          _estimateWith(
            status: FertilityEstimateStatus.lowConfidence,
            ovulation: _isoOffset(5),
            windowStart: _isoOffset(0),
            windowEnd: _isoOffset(6),
          ),
        ),
      );
      expect(find.text('Estimate uncertain'), findsOneWidget);
      expect(find.text('Estimated fertile window'), findsNothing);
      expect(find.textContaining('Estimated ovulation day'), findsNothing);
      expect(find.textContaining('Sep'), findsNothing);
    });

    testWidgets('INSUFFICIENT_DATA is a useful empty state', (tester) async {
      await pumpCard(
        tester,
        Fresh<FertilityEstimate?>(
          _estimateWith(status: FertilityEstimateStatus.insufficientData),
        ),
      );
      expect(find.text('Not enough information yet'), findsOneWidget);
      expect(find.text('Log fertility signs'), findsOneWidget);
      expect(find.text('Estimated fertile window'), findsNothing);
    });

    testWidgets('SUPPRESSED hides dates with neutral copy', (tester) async {
      await pumpCard(
        tester,
        Fresh<FertilityEstimate?>(
          _estimateWith(status: FertilityEstimateStatus.suppressed),
        ),
      );
      expect(find.text('Fertility estimates paused'), findsOneWidget);
      expect(find.text('Estimated fertile window'), findsNothing);
      expect(find.textContaining('Estimated ovulation day'), findsNothing);
    });

    testWidgets('banned guarantee/contraception language never appears', (
      tester,
    ) async {
      await pumpCard(
        tester,
        Fresh<FertilityEstimate?>(
          _estimateWith(
            status: FertilityEstimateStatus.available,
            ovulation: _isoOffset(5),
            windowStart: _isoOffset(0),
            windowEnd: _isoOffset(6),
          ),
        ),
      );
      for (final banned in [
        'safe days',
        'unsafe days',
        'guaranteed fertile days',
        'guaranteed infertile days',
        'risk-free days',
        'danger days',
      ]) {
        expect(
          find.textContaining(RegExp(banned, caseSensitive: false)),
          findsNothing,
          reason: 'banned phrase: $banned',
        );
      }
    });

    testWidgets('offline estimate state guides to connect', (tester) async {
      await pumpCard(
        tester,
        const Unavailable<FertilityEstimate?>('offline (fake)'),
      );
      expect(find.text('Estimates need a connection'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------- D. observations UI
  group('D. observation logging flow', () {
    testWidgets('three sign types render; LH saves through the repo', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: FertilityLogScreen(initialDate: _isoOffset(-1)),
      );

      expect(find.text('LH test'), findsOneWidget);
      expect(find.text('Basal body temperature'), findsOneWidget);
      expect(find.text('Cervical mucus'), findsOneWidget);
      // Mucus scale is the dedicated vocabulary (egg_white present)…
      expect(find.text('Egg white'), findsOneWidget);
      // …and never reuses the retired generic-discharge wording.
      expect(find.text('Slippery / Stretchy'), findsNothing);

      await tester.tap(find.text('Positive'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Fertility sign saved.'), findsOneWidget);
      final repo = ReproductiveRepository(db, api);
      final listed = await repo.loadObservationsLocal(_user);
      expect(listed.dataOrNull!.length, 1);
      expect(listed.dataOrNull!.single.lhResult, LhResults.positive);
    });

    testWidgets('invalid BBT input shows inline guidance, no save', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: FertilityLogScreen(initialDate: _isoOffset(-1)),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Temperature (°C)'),
        'not-a-number',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save').at(1));
      await tester.pump();
      expect(find.textContaining('measured temperature'), findsOneWidget);
      expect(api.createObservationCalls, 0);
    });
  });

  // ---------------------------------------------------------- E. pregnancy UI
  group('E. pregnancy mode experience', () {
    test('no automatic activation from other reproductive work', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-1),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.positive,
      );
      await repo.saveAging(_user, 'some context');
      await repo.loadEstimate();

      expect(api.serverPregnancy, isNull);
      expect(api.putPregnancyCalls, 0);
      expect(api.patchPregnancyCalls, 0);
    });

    testWidgets('off state is explicit with no inference language', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const PregnancyModeScreen(),
      );

      expect(find.textContaining('Pregnancy mode is off'), findsOneWidget);
      // Section header and action share the explicit activation wording.
      expect(find.text('Turn on pregnancy mode'), findsNWidgets(2));
      expect(
        find.textContaining('never turns it on from late periods'),
        findsOneWidget,
      );
      // Never implies suspicion from cycle data.
      expect(
        find.textContaining(
          RegExp('you may be pregnant', caseSensitive: false),
        ),
        findsNothing,
      );
    });

    testWidgets('clinician dating displays with provenance + timeline', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);
      await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.clinician,
          estimatedDueDate: _isoOffset(180),
          datingNote: 'dating scan 12w',
        ),
      );
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const PregnancyModeScreen(),
      );

      expect(find.text('Pregnancy mode is on'), findsOneWidget);
      // Summary row + form label both carry the friendly dating wording.
      expect(find.text('Clinician-established due date'), findsNWidgets(2));
      expect(find.text('Clinically confirmed'), findsOneWidget);
      expect(find.textContaining('Gestational age'), findsOneWidget);
      // Saved note renders in the summary and initializes the form field.
      expect(find.textContaining('dating scan 12w'), findsNWidgets(2));
      // Raw backend codes never surface.
      expect(find.text('CLINICALLY_CONFIRMED'), findsNothing);
      expect(find.text('clinician_established_due_date'), findsNothing);
    });

    testWidgets('lmp dating uses estimate wording', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);
      await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.lmp,
          estimatedDueDate: _isoOffset(200),
          lmpDate: _isoOffset(-80),
        ),
      );
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const PregnancyModeScreen(),
      );

      // Summary row + form controls both carry the friendly wording.
      expect(find.text('Last menstrual period'), findsNWidgets(2));
      expect(find.text('Estimated due date'), findsNWidgets(2));
      expect(find.text('Estimated'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------- F. suppression
  group('F. pregnancy suppression of fertility presentation', () {
    test('active pregnancy suppresses dates; deactivation restores', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()
        ..cannedEstimate = _estimateWith(
          status: FertilityEstimateStatus.available,
          ovulation: _isoOffset(5),
          windowStart: _isoOffset(0),
          windowEnd: _isoOffset(6),
        );
      final repo = ReproductiveRepository(db, api);

      // Phase 2 behavior preserved while inactive.
      var estimate = await repo.loadEstimate();
      expect(estimate.dataOrNull!.status, FertilityEstimateStatus.available);
      expect(estimate.dataOrNull!.hasDates, isTrue);

      await repo.savePregnancyPut(
        _user,
        PregnancyContext(userId: _user, isActive: true),
      );
      estimate = await repo.loadEstimate();
      expect(estimate.dataOrNull!.status, FertilityEstimateStatus.suppressed);
      expect(estimate.dataOrNull!.estimatedOvulationDate, isNull);
      expect(estimate.dataOrNull!.fertileWindowStart, isNull);
      expect(estimate.dataOrNull!.fertileWindowEnd, isNull);

      await repo.deactivatePregnancy(_user);
      estimate = await repo.loadEstimate();
      expect(estimate.dataOrNull!.status, FertilityEstimateStatus.available);
      expect(estimate.dataOrNull!.hasDates, isTrue);
    });

    testWidgets('home shows pregnancy summary instead of fertile dates', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()
        ..cannedEstimate = _estimateWith(
          status: FertilityEstimateStatus.available,
          ovulation: _isoOffset(5),
          windowStart: _isoOffset(0),
          windowEnd: _isoOffset(6),
        );
      final repo = ReproductiveRepository(db, api);
      await repo.savePregnancyPut(
        _user,
        PregnancyContext(
          userId: _user,
          isActive: true,
          datingSource: DatingSources.ultrasound,
          estimatedDueDate: _isoOffset(180),
        ),
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_user),
            isOfflineTrackingProvider.overrideWithValue(false),
            appDatabaseProvider.overrideWithValue(db),
            reproductiveRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(0.6)),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: ReproductiveHomeBlock()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Pregnancy mode is on'), findsOneWidget);
      expect(find.text('Estimated fertile window'), findsNothing);
    });
  });

  // ---------------------------------------------------------- G. aging
  group('G. reproductive-aging context', () {
    test('context retrieval is verbatim user input', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      const notes = 'Cycles feel different lately — noting for myself.';
      await repo.saveAging(_user, notes);
      final loaded = await repo.loadAging(_user);
      expect(loaded.dataOrNull!.notes, notes);
      expect(api.serverAging!.notes, notes);
    });

    testWidgets('aging screen: no diagnosis language, recorded marker', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);
      await repo.saveAging(_user, 'noting changes');

      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const AgingContextScreen(),
      );

      expect(find.text('You recorded this'), findsOneWidget);
      expect(
        find.textContaining('never treated as a diagnosis'),
        findsOneWidget,
      );
      for (final banned in [
        'You are perimenopausal',
        'in menopause',
        'postmenopause',
        'MenoMate detected',
        'perimenopause stage',
      ]) {
        expect(
          find.textContaining(RegExp(banned, caseSensitive: false)),
          findsNothing,
          reason: 'banned diagnostic phrase: $banned',
        );
      }
    });

    testWidgets('aging empty state invites optional context', (tester) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: const AgingContextScreen(),
      );

      expect(find.text('Save context'), findsOneWidget);
      expect(find.text('You recorded this'), findsNothing);
    });
  });

  // ---------------------------------------------------------- H. isolation
  group('H. isolation and offline safety', () {
    test(
      'rows are keyed by the caller id, never shared across users',
      () async {
        final db = _memoryDb();
        addTearDown(db.close);
        final api = FakeApiService();
        final repo = ReproductiveRepository(db, api);

        await repo.saveObservation(
          _user,
          observationDate: _isoOffset(-1),
          observationType: ObservationTypes.lhTest,
          lhResult: LhResults.positive,
        );
        await repo.saveAging(_user, 'mine');
        await repo.savePregnancyPut(
          _user,
          PregnancyContext(userId: _user, isActive: true),
        );

        expect(
          await repo.loadObservationsLocal('user-b'),
          isA<NoData<List<FertilityObservation>>>(),
        );
        expect(await repo.loadAgingLocal('user-b'), isA<NoData>());
        expect(await repo.loadPregnancyLocal('user-b'), isA<NoData>());
      },
    );

    test('sign-out wipe clears every reproductive row', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      final repo = ReproductiveRepository(db, api);

      await repo.saveObservation(
        _user,
        observationDate: _isoOffset(-1),
        observationType: ObservationTypes.bbt,
        bbtCelsius: 36.7,
        localOnly: true,
      );
      await repo.savePregnancyPut(
        _user,
        PregnancyContext(userId: _user, isActive: true),
        localOnly: true,
      );
      await repo.saveAging(_user, 'note', localOnly: true);
      expect(await db.hasUnsyncedData(), isTrue);

      await db.clearAllUserData();
      expect(await db.hasUnsyncedData(), isFalse);
      expect(await (db.select(db.localFertilityObservations)).get(), isEmpty);
      expect(await (db.select(db.localPregnancyContext)).get(), isEmpty);
      expect(await (db.select(db.localAgingContext)).get(), isEmpty);
    });

    test('offline adoption moves reproductive rows under consent', () async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService()..offline = true;
      final repo = ReproductiveRepository(db, api);

      await repo.saveObservation(
        kOfflineUserId,
        observationDate: _isoOffset(-1),
        observationType: ObservationTypes.lhTest,
        lhResult: LhResults.negative,
        localOnly: true,
      );
      await repo.saveAging(kOfflineUserId, 'offline note', localOnly: true);
      await repo.savePregnancyPut(
        kOfflineUserId,
        PregnancyContext(userId: kOfflineUserId, isActive: true),
        localOnly: true,
      );

      final counts = await db.reproductiveAdoptableCounts();
      expect(counts.observations, 1);
      expect(counts.pregnancy, isTrue);
      expect(counts.aging, isTrue);

      await db.adoptOfflineData(_user);
      final moved = await repo.loadObservationsLocal(_user);
      expect(moved.dataOrNull!.length, 1);
      expect(
        (await repo.loadAgingLocal(_user)).dataOrNull!.notes,
        'offline note',
      );
      expect(
        (await repo.loadPregnancyLocal(_user)).dataOrNull!.isActive,
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------- I. accessibility
  group('I. accessibility semantics', () {
    testWidgets('estimate card exposes a meaningful screen-reader label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(),
            child: MaterialApp(
              home: Scaffold(
                body: FertilityEstimateCard(
                  state: Fresh<FertilityEstimate?>(
                    _estimateWith(
                      status: FertilityEstimateStatus.available,
                      ovulation: _isoOffset(5),
                      windowStart: _isoOffset(0),
                      windowEnd: _isoOffset(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          RegExp('Estimated fertile window', caseSensitive: false),
        ),
        findsWidgets,
      );
    });

    testWidgets('estimate card survives large text scaling', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: FertilityEstimateCard(
                    state: Fresh<FertilityEstimate?>(
                      _estimateWith(
                        status: FertilityEstimateStatus.available,
                        ovulation: _isoOffset(5),
                        windowStart: _isoOffset(0),
                        windowEnd: _isoOffset(6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Estimated fertile window'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LH chips expose button semantics with selection', (
      tester,
    ) async {
      final db = _memoryDb();
      addTearDown(db.close);
      final api = FakeApiService();
      await _pumpScreen(
        tester,
        db: db,
        api: api,
        screen: FertilityLogScreen(initialDate: _isoOffset(-1)),
      );
      await tester.tap(find.text('Positive'));
      await tester.pump();
      expect(find.bySemanticsLabel('LH result: Positive'), findsOneWidget);
    });
  });
}

/// Fake whose reproductive reads fail with [AuthFailure], proving the
/// repository rethrows auth errors instead of swallowing them.
class _AuthFailingFake extends FakeApiService {
  @override
  Future<PregnancyContext> fetchPregnancy(String userId) async {
    throw const AuthFailure('Session expired.');
  }

  @override
  Future<FertilityEstimate> fetchFertilityEstimate({String? asOf}) async {
    throw const AuthFailure('Session expired.');
  }
}
