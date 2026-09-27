extends RefCounted
## The effect chain on the "Speech" bus. Pure setup, unit-tested.
##
## Voice clips are 24 kHz MP3 (all the free Edge endpoint serves). Godot's
## cubic resampler up to the 44.1/48 kHz mix mirrors the whole voice into
## 12-20 kHz (only 8-16 dB down on broadband content: an audible metallic
## fizz) and rolls the 8-11 kHz "air" off by 2-5 dB. The chain undoes both:
##
##   0  PitchShift   pulls sped-up speech back to natural pitch (off at 1x)
##   1  HighShelf    restores the resampler's top-octave roll-off
##   2-5 LowPass x4  8th-order Butterworth at 11.5 kHz removes the images
##   6  HardLimiter  small loudness lift with a safe ceiling
##
## The filters sit after the pitch shift so they also clean the images it
## shifts down at 0.9x-1.3x.

const PITCH_SHIFT := 0
const SHELF_HZ := 10000.0
const SHELF_GAIN := 1.5
const ANTI_IMAGE_HZ := 11500.0
## Q of each biquad in an 8th-order Butterworth. Godot uses `resonance` as Q
## directly for a single-stage (FILTER_6DB) filter; multi-stage filters reuse
## one Q for every stage, which is why they cannot be used here.
const ANTI_IMAGE_Q: Array[float] = [0.51, 0.60, 0.90, 2.56]
## Edge clips sit ~1.5 LU under typical commercial TTS delivery (-20 vs -18.5 LUFS).
const PRE_GAIN_DB := 1.5
const CEILING_DB := -1.0


static func build(bus_idx: int) -> void:
	var shift := AudioEffectPitchShift.new()
	# FFT_SIZE_4096 is broken in 4.7.2 (errors and outputs garbage); 2048 with
	# oversampling 4 measured as close to a Rubber Band stretch as any setting.
	shift.fft_size = AudioEffectPitchShift.FFT_SIZE_2048
	shift.oversampling = 4
	AudioServer.add_bus_effect(bus_idx, shift, PITCH_SHIFT)
	var shelf := AudioEffectHighShelfFilter.new()
	shelf.cutoff_hz = SHELF_HZ
	shelf.gain = SHELF_GAIN
	AudioServer.add_bus_effect(bus_idx, shelf)
	for q in ANTI_IMAGE_Q:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = ANTI_IMAGE_HZ
		lp.resonance = q
		lp.db = AudioEffectFilter.FILTER_6DB
		AudioServer.add_bus_effect(bus_idx, lp)
	var limiter := AudioEffectHardLimiter.new()
	limiter.pre_gain_db = PRE_GAIN_DB
	limiter.ceiling_db = CEILING_DB
	AudioServer.add_bus_effect(bus_idx, limiter)


## Playback speed is applied on the player (pitch_scale); the shift undoes the
## pitch rise and is bypassed entirely at 1x so normal speed is untouched.
static func apply_speed(bus_idx: int, speed: float) -> void:
	if bus_idx < 0 or AudioServer.get_bus_effect_count(bus_idx) <= PITCH_SHIFT:
		return
	var shift := AudioServer.get_bus_effect(bus_idx, PITCH_SHIFT) as AudioEffectPitchShift
	if shift != null:
		shift.pitch_scale = AudioSettings.pitch_compensation(speed)
	AudioServer.set_bus_effect_enabled(bus_idx, PITCH_SHIFT, not is_equal_approx(speed, 1.0))
