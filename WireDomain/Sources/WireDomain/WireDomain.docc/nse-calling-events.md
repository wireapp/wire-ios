# NSE Calling Events

## Overview

The Notification Service Extension processes calling events in batches through `ProcessCallingEventsUseCase`.
The use case bridges synchronized Wire events into AVS through `AVSCallingEventService`, and
`CallKitReportingCoordinator` translates the final AVS callback result into CallKit reporting actions.

This allows the NSE to process all call events as a batch and receive the resulting call actions only after
synchronization has finished.

## Flow

1. `NSEClientScope` creates and retains an `AVSCallingEventService` for the NSE client scope. During
   initialization, `AVSCallingEventService` calls `wcall_event_create()` and keeps the returned handle for all
   subsequent AVS API calls.

2. When a notification request is handled, `NSEClientScope` collects the synchronized event batches and invokes
   `ProcessCallingEventsUseCase`.

3. `ProcessCallingEventsUseCase` starts the AVS batch with `AVSCallingEventService.start()`, which maps to
   `wcall_event_start()`.

4. During notification sync processing, every call-related event is converted into AVS parameters and passed to
   `AVSCallingEventService.process(...)`, which maps to `wcall_event_process()`.

5. Once all batches have been processed, `ProcessCallingEventsUseCase` calls `AVSCallingEventService.end()`,
   which maps to `wcall_event_end()`.

6. AVS evaluates the complete batch and invokes the callbacks registered through `wcall_event_create()`:
   `incomingh`, `missedh`, or `closeh`.

7. `CallKitReportingCoordinator` receives those callbacks through `AVSCallingEventServiceProtocol` closures:
   `onIncomingCall`, `onMissedCall`, and `onCallClosed`.

8. The coordinator reports the resulting CallKit action and waits for pending reporting work before the NSE
   continues with regular notification generation.

## Callback Results

After `wcall_event_end()` is called, AVS evaluates the processed call events and invokes one of the registered
callbacks depending on the final state of each call:

- `incomingh` for a new incoming call
- `missedh` for a missed call
- `closeh` for a call that should be closed

In WireDomain, these callbacks are exposed by `AVSCallingEventService` as Swift closures. `CallKitReportingCoordinator`
registers those closures and translates them into CallKit reporting behavior for the NSE.
