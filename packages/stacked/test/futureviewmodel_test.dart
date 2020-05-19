import 'package:flutter_test/flutter_test.dart';
import 'package:stacked/stacked.dart';

const _SingleFutureExceptionFailMessage = 'Future to Run failed';

class TestFutureViewModel extends FutureViewModel<int> {
  final bool fail;
  TestFutureViewModel({this.fail = false});

  int numberToReturn = 5;
  bool dataCalled = false;

  @override
  Future<int> futureToRun() async {
    if (fail) throw Exception(_SingleFutureExceptionFailMessage);
    await Future.delayed(Duration(milliseconds: 20));
    return numberToReturn;
  }

  @override
  void onData(int data) {
    dataCalled = true;
  }
}

const String NumberDelayFuture = 'delayedNumber';
const String StringDelayFuture = 'delayedString';
const String _NumberDelayExceptionMessage = 'getNumberAfterDelay failed';

class TestMultipleFutureViewModel extends MultipleFutureViewModel {
  final bool failOne;
  TestMultipleFutureViewModel({this.failOne = false});

  int numberToReturn = 5;

  @override
  Map<String, Future Function()> get futuresMap => {
        NumberDelayFuture: getNumberAfterDelay,
        StringDelayFuture: getStringAfterDelay,
      };

  Future<int> getNumberAfterDelay() async {
    if (failOne) {
      throw Exception(_NumberDelayExceptionMessage);
    }
    await Future.delayed(Duration(milliseconds: 300));
    return numberToReturn;
  }

  Future<String> getStringAfterDelay() async {
    await Future.delayed(Duration(milliseconds: 400));
    return 'String data';
  }
}

void main() {
  group('FutureViewModel', () {
    test('When future is complete data should be set and ready', () async {
      var futureViewModel = TestFutureViewModel();
      await futureViewModel.runFuture();
      expect(futureViewModel.data, 5);
      expect(futureViewModel.dataReady, true);
    });

    test('When a future fails it should indicate there\'s an error and no data',
        () async {
      var futureViewModel = TestFutureViewModel(fail: true);
      await futureViewModel.runFuture();
      expect(futureViewModel.hasError, true);
      expect(futureViewModel.data, null,
          reason: 'No data should be set when there\'s a failure.');
      expect(futureViewModel.dataReady, false);
    });

    test('When a future runs it should indicate busy', () async {
      var futureViewModel = TestFutureViewModel();
      futureViewModel.runFuture();
      expect(futureViewModel.isBusy, true);
    });

    test('When a future fails it should indicate NOT busy', () async {
      var futureViewModel = TestFutureViewModel(fail: true);
      await futureViewModel.runFuture();
      expect(futureViewModel.isBusy, false);
    });

    test('When a future fails it should set error to exception', () async {
      var futureViewModel = TestFutureViewModel(fail: true);
      await futureViewModel.runFuture();
      expect(futureViewModel.error.message, _SingleFutureExceptionFailMessage);
    });

    test('When a future fails onData should not be called', () async {
      var futureViewModel = TestFutureViewModel(fail: true);
      await futureViewModel.runFuture();
      expect(futureViewModel.dataCalled, false);
    });

    test('When a future passes onData should not called', () async {
      var futureViewModel = TestFutureViewModel();
      await futureViewModel.runFuture();
      expect(futureViewModel.dataCalled, true);
    });

    group('Dynamic Source Tests', () {
      test('notifySourceChanged - When called should re-run Future', () async {
        var futureViewModel = TestFutureViewModel();
        await futureViewModel.runFuture();
        expect(futureViewModel.data, 5);
        futureViewModel.numberToReturn = 10;
        futureViewModel.notifySourceChanged();
        await futureViewModel.runFuture();
        expect(futureViewModel.data, 10);
      });
    });
  });

  group('MultipleFutureViewModel', () {
    test(
        'When running multiple futures the associated key should hold the value when complete',
        () async {
      var futureViewModel = TestMultipleFutureViewModel();
      await futureViewModel.runFutures();

      expect(futureViewModel.dataMap[NumberDelayFuture], 5);
      expect(futureViewModel.dataMap[StringDelayFuture], 'String data');
    });

    test(
        'When one of multiple futures fail only the failing one should have an error',
        () async {
      var futureViewModel = TestMultipleFutureViewModel(failOne: true);
      await futureViewModel.runFutures();

      expect(futureViewModel.hasError(NumberDelayFuture), true);
      expect(futureViewModel.hasError(StringDelayFuture), false);
    });

    test(
        'When one of multiple futures fail the passed one should have data and failing one not',
        () async {
      var futureViewModel = TestMultipleFutureViewModel(failOne: true);
      await futureViewModel.runFutures();

      expect(futureViewModel.dataMap[NumberDelayFuture], null);
      expect(futureViewModel.dataMap[StringDelayFuture], 'String data');
    });

    test('When multiple futures run the key should be set to indicate busy',
        () async {
      var futureViewModel = TestMultipleFutureViewModel();
      futureViewModel.runFutures();

      expect(futureViewModel.busy(NumberDelayFuture), true);
      expect(futureViewModel.busy(StringDelayFuture), true);
    });

    test(
        'When multiple futures are complete the key should be set to indicate NOT busy',
        () async {
      var futureViewModel = TestMultipleFutureViewModel();
      await futureViewModel.runFutures();

      expect(futureViewModel.busy(NumberDelayFuture), false);
      expect(futureViewModel.busy(StringDelayFuture), false);
    });

    test('When a future fails busy should be set to false', () async {
      var futureViewModel = TestMultipleFutureViewModel(failOne: true);
      await futureViewModel.runFutures();

      expect(futureViewModel.busy(NumberDelayFuture), false);
      expect(futureViewModel.busy(StringDelayFuture), false);
    });

    test('When a future fails should set error for future key', () async {
      var futureViewModel = TestMultipleFutureViewModel(failOne: true);
      await futureViewModel.runFutures();

      expect(futureViewModel.getError(NumberDelayFuture).message,
          _NumberDelayExceptionMessage);

      expect(futureViewModel.getError(StringDelayFuture), null);
    });

    group('Dynamic Source Tests', () {
      test('notifySourceChanged - When called should re-run Future', () async {
        var futureViewModel = TestMultipleFutureViewModel();
        await futureViewModel.runFutures();
        expect(futureViewModel.dataMap[NumberDelayFuture], 5);
        futureViewModel.numberToReturn = 10;
        futureViewModel.notifySourceChanged();
        await futureViewModel.runFutures();
        expect(futureViewModel.dataMap[NumberDelayFuture], 10);
      });
    });
  });
}
