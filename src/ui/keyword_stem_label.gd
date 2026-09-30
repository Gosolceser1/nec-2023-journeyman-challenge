class_name KeywordStemLabel
extends RichTextLabel
## The question stem (HuntView). Its keywords carry a [hint] so HuntView can
## tell which one is under a pointer or finger (get_tooltip), but hovering
## shows no tooltip: the INDEX line names the entry, and the tooltip covered the
## explanation line beneath the stem.


## An invisible custom tooltip is the engine's way to show none.
func _make_custom_tooltip(_for_text: String) -> Object:
	var none := Control.new()
	none.visible = false
	return none
