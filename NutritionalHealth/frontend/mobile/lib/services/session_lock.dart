class SessionLock {
  // In-memory session-only flag. True means guest selections are locked
  // for the current app session. This is intentionally not persisted so
  // restarting the app clears the lock.
  static bool guestSelectionsLocked = false;
}
