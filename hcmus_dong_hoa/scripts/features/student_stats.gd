extends Node
# THONG SO SINH VIEN: GPA, ren luyen, tien, nang luong va XP.
# TKB va dong ho van do main.gd / schedule_data.gd quan ly.

signal drl_changed(amount: int, reason: String)
signal money_changed(value: int, delta: int, reason: String)
signal energy_changed(value: int, delta: int, reason: String)
signal xp_changed(value: int, level: int)

const GPA_MAX := 4.0
const DRL_MAX := 100
const ENERGY_MAX := 100
const MONEY_MAX_DISPLAY := 200000
const XP_PER_LEVEL := 100

var gpa := 3.0
var drl := 70
var money := 50000
var energy := 100
var xp := 0
var level := 1

func add_drl(amount: int, reason: String = "") -> void:
	var before := drl
	drl = clampi(drl + amount, 0, DRL_MAX)
	if drl != before:
		drl_changed.emit(drl - before, reason)

func set_gpa(value: float) -> void:
	gpa = clampf(value, 0.0, GPA_MAX)

func add_money(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
	var before := money
	money = maxi(0, money + amount)
	if money != before:
		money_changed.emit(money, money - before, reason)

func spend_money(amount: int, reason: String = "") -> bool:
	if amount < 0 or money < amount:
		return false
	add_money(-amount, reason)
	return true

func add_energy(amount: int, reason: String = "") -> void:
	if amount == 0:
		return
	var before := energy
	energy = clampi(energy + amount, 0, ENERGY_MAX)
	if energy != before:
		energy_changed.emit(energy, energy - before, reason)

func spend_energy(amount: int, reason: String = "") -> bool:
	if amount < 0 or energy < amount:
		return false
	add_energy(-amount, reason)
	return true

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= XP_PER_LEVEL:
		xp -= XP_PER_LEVEL
		level += 1
	xp_changed.emit(xp, level)

func gpa_ratio() -> float:
	return gpa / GPA_MAX

func drl_ratio() -> float:
	return float(drl) / DRL_MAX

func energy_ratio() -> float:
	return float(energy) / ENERGY_MAX

func money_ratio() -> float:
	return clampf(float(money) / MONEY_MAX_DISPLAY, 0.0, 1.0)

func gpa_text() -> String:
	return "%.2f/%.1f" % [gpa, GPA_MAX]

func drl_text() -> String:
	return "%d/%d" % [drl, DRL_MAX]

func money_text() -> String:
	return "%dk" % int(money / 1000.0)

func energy_text() -> String:
	return "%d/%d" % [energy, ENERGY_MAX]

func bar_color(ratio: float) -> Color:
	return Color.from_hsv(clampf(ratio, 0.0, 1.0) * 0.33, 0.8, 0.95)
