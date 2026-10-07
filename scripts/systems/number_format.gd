class_name NumberFormat
extends RefCounted

static func compact(value: int) -> String:
	var amount := maxi(0, value)
	if amount < 1000: return str(amount)
	if amount >= 999950000 and amount < 1000000000: amount = 1000000000
	elif amount >= 999950 and amount < 1000000: amount = 1000000
	for unit in [{"value": 1000000000, "suffix": "B"}, {"value": 1000000, "suffix": "M"}, {"value": 1000, "suffix": "K"}]:
		if amount >= int(unit.value):
			var short := float(amount) / float(unit.value)
			var digits := 0 if short >= 100.0 else 1
			var rounded := snappedf(short, 0.1) if digits == 1 else floorf(short)
			return ("%.1f" % rounded if digits == 1 else "%.0f" % rounded) + str(unit.suffix)
	return str(amount)
