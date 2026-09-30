class RefreshPolicySettings {
  const RefreshPolicySettings({
    this.enabled = true,
    this.maxAge = const Duration(minutes: 5),
    this.mode = RefreshPolicy.immediate,
  });

  final bool enabled;
  final Duration maxAge;
  final RefreshPolicy mode;
}
