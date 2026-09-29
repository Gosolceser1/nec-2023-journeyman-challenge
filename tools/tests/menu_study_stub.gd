extends RefCounted
## Stand-in for the study tools' entry script in test_menu.gd: counts the
## calls data/menu.json's study_tools block routes to it.

static var calls: Array = []


static func open(_main: Node, id: String) -> void:
	calls.append("open:" + id)


static func attach(_main: Node) -> void:
	calls.append("attach")


static func on_question(_main: Node) -> void:
	calls.append("question")


static func on_answered(_main: Node, _record: Dictionary, correct: bool, graded: bool) -> void:
	calls.append("answered:%s:%s" % [correct, graded])


static func handle_back(_main: Node) -> bool:
	calls.append("back")
	return true
