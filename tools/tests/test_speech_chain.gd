extends SceneTree
## SpeechChain: the Speech bus effects. The promises: the pitch shift is first
## and bypassed at 1x, the shelf + Butterworth anti-image stack follows it (so
## shifted images are cleaned too), the pitch shift never uses the broken 4096
## FFT, and the limiter caps the lifted voice below full scale.

const SpeechChain = preload("res://fx/speech_chain.gd")

var failures: Array[String] = []
var checks := 0


func check(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		failures.append(label)
		print("  FAIL: %s" % label)


func _initialize() -> void:
	print("=== build ===")
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	SpeechChain.build(idx)
	var n := AudioServer.get_bus_effect_count(idx)
	check(n == 3 + SpeechChain.ANTI_IMAGE_Q.size(), "shift + shelf + %d biquads + limiter" % SpeechChain.ANTI_IMAGE_Q.size())
	var shift := AudioServer.get_bus_effect(idx, SpeechChain.PITCH_SHIFT) as AudioEffectPitchShift
	check(shift != null, "pitch shift sits at PITCH_SHIFT (index 0)")
	check(shift != null and shift.fft_size == AudioEffectPitchShift.FFT_SIZE_2048, "pitch shift avoids the broken 4096 FFT")
	var shelf := AudioServer.get_bus_effect(idx, 1) as AudioEffectHighShelfFilter
	check(shelf != null and shelf.gain > 1.0, "high shelf restores the resampler roll-off")
	var qs: Array[float] = []
	var cutoffs_ok := true
	var single_stage := true
	for i in SpeechChain.ANTI_IMAGE_Q.size():
		var lp := AudioServer.get_bus_effect(idx, 2 + i) as AudioEffectLowPassFilter
		if lp == null:
			break
		qs.append(lp.resonance)
		cutoffs_ok = cutoffs_ok and is_equal_approx(lp.cutoff_hz, SpeechChain.ANTI_IMAGE_HZ)
		single_stage = single_stage and lp.db == AudioEffectFilter.FILTER_6DB
	check(qs.size() == SpeechChain.ANTI_IMAGE_Q.size(), "one low-pass per Butterworth section")
	var qs_match := qs.size() == SpeechChain.ANTI_IMAGE_Q.size()
	for i in qs.size():
		qs_match = qs_match and absf(qs[i] - SpeechChain.ANTI_IMAGE_Q[i]) < 1e-4
	check(qs_match, "sections carry the Butterworth Qs")
	check(cutoffs_ok, "every section at the anti-image cutoff")
	check(single_stage, "single-stage biquads (multi-stage would reuse one Q)")
	check(SpeechChain.ANTI_IMAGE_HZ > 11000.0 and SpeechChain.ANTI_IMAGE_HZ < 12000.0, "cutoff keeps the voice band, below the 12 kHz source Nyquist")
	var limiter := AudioServer.get_bus_effect(idx, n - 1) as AudioEffectHardLimiter
	check(limiter != null, "limiter is last")
	check(limiter != null and limiter.ceiling_db < 0.0, "limiter ceiling below full scale")

	print("=== apply_speed ===")
	SpeechChain.apply_speed(idx, 1.0)
	check(not AudioServer.is_bus_effect_enabled(idx, SpeechChain.PITCH_SHIFT), "1x: pitch shift bypassed")
	var others_on := true
	for i in range(1, n):
		others_on = others_on and AudioServer.is_bus_effect_enabled(idx, i)
	check(others_on, "1x: filters and limiter stay on")
	SpeechChain.apply_speed(idx, 1.15)
	check(AudioServer.is_bus_effect_enabled(idx, SpeechChain.PITCH_SHIFT), "1.15x: pitch shift on")
	check(is_equal_approx(shift.pitch_scale, 1.0 / 1.15), "1.15x: shift undoes the pitch rise")
	SpeechChain.apply_speed(idx, 0.9)
	check(is_equal_approx(shift.pitch_scale, 1.0 / 0.9), "0.9x: shift raises pitch back")
	SpeechChain.apply_speed(-1, 1.3)
	check(true, "missing bus is a no-op")
	AudioServer.remove_bus(idx)

	print("")
	print("checks: %d  failures: %d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
