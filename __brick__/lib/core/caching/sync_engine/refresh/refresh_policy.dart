enum RefreshPolicy { immediate, background, manual } //default background

class RefreshPolicySettings {
  const RefreshPolicySettings({
    this.enabled = true,
    this.maxAge = const Duration(minutes: 5),
    this.mode = RefreshPolicy.background,
  });

  final bool enabled;
  final Duration maxAge;
  final RefreshPolicy mode;
}
