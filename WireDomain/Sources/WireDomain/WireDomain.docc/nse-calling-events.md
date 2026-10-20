# NSE Calling Events

## Overview

The Notification Service Extension processes calling events in batches through `ProcessCallingEventsUseCase`.
The use case bridges synchronized Wire events into AVS through `AVSCallingEventService`, and
`CallKitReportingCoordinator` translates the final AVS callback result into CallKit reporting actions.

This allows the NSE to process all call events as a batch and receive the resulting call actions only after
synchronization has finished.

## Flow

1. `AVSCallingEventService` is a process-level singleton, accessed via `AVSCallingEventService.shared(userID:clientID:)`.
   On first access it calls `wcall_event_create()`, which registers C-level callbacks and stores a `contextRef`
   (an opaque pointer to the service instance) inside the AVS library. That `contextRef` is permanent: subsequent
   calls to `wcall_event_create()` with the same `userID`/`clientID` return the existing handle without updating
   the stored pointer. The singleton ensures the handle and `contextRef` remain stable across NSE invocations.

2. When a notification request is handled, `NSEClientScope` creates a fresh `CallKitReportingCoordinator` (actor)
   for that notification. During initialization the coordinator registers its `onIncomingCall` and `onCallClosed`
   closures on the shared `AVSCallingEventService`, replacing the previous notification's closures. All subsequent
   AVS callbacks will be delivered to this coordinator.

3. `NSEClientScope` collects the synchronized event batches and invokes `ProcessCallingEventsUseCase`.

4. `ProcessCallingEventsUseCase` starts the AVS batch with `AVSCallingEventService.start()`, which maps to
   `wcall_event_start()`.

5. During notification sync processing, every call-related event is converted into AVS parameters. Before
   forwarding each event to AVS, `ProcessCallingEventsUseCase` calls `CallKitReportingCoordinator.setCallerName(_:for:)`
   to pre-populate the display name for that conversation. This is necessary because name resolution requires
   async Core Data access and must happen before the AVS callback fires.

6. Each event is then passed to `AVSCallingEventService.process(...)`, which maps to `wcall_event_process()`.

7. Once all batches have been processed, `ProcessCallingEventsUseCase` calls `AVSCallingEventService.end()`,
   which maps to `wcall_event_end()`.

8. AVS evaluates the complete batch and invokes the callbacks registered through `wcall_event_create()`:
   `incoming`, `missed`, or `close`.

9. `CallKitReportingCoordinator` receives those callbacks through `AVSCallingEventServiceProtocol` closures:
   `onIncomingCall`, `onMissedCall`, and `onCallClosed`.

10. The coordinator looks up the pre-populated caller name, reports the resulting CallKit action, and waits for
    pending reporting work before the NSE continues with regular notification generation.

## Callback Results

After `wcall_event_end()` is called, AVS evaluates the processed call events and invokes one of the registered
callbacks depending on the final state of each call:

- `incoming` for a new incoming call
- `missed` for a missed call
- `close` for a call that should be closed

In WireDomain, these callbacks are exposed by `AVSCallingEventService` as Swift closures. `CallKitReportingCoordinator`
registers those closures and translates them into CallKit reporting behavior for the NSE.
