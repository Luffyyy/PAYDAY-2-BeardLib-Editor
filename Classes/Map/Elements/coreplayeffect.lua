EditorPlayEffect = EditorPlayEffect or class(MissionScriptEditor)
EditorPlayEffect.USES_POINT_ORIENTATION = true
function EditorPlayEffect:create_element()
	EditorPlayEffect.super.create_element(self)
	self._element.class = "ElementPlayEffect"
	self._element.values.effect = "none"
	self._element.values.screen_space = false
	self._element.values.base_time = 0
	self._element.values.random_time = 0
	self._element.values.max_amount = 0
end

function EditorPlayEffect:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("screen_space", {help = "Play in Screen Space"})
	self:PathCtrl("effect", "effect")
	self:NumberCtrl("base_time", {floats = 2, min = 0, help = "This is the minimum time to wait before spawning next effect"})
	self:NumberCtrl("random_time", {floats = 2, min = 0, help = "Random time is added to minimum time to give the time between effect spawns"})
	self:NumberCtrl("max_amount", {floats = 0, min = 0, help = "Maximum amount of spawns when repeating effects (0 = unlimited)"})
end

EditorStopEffect = EditorStopEffect or class(MissionScriptEditor)
function EditorStopEffect:create_element()
	EditorStopEffect.super.create_element(self)
	self._element.class = "ElementStopEffect"
	self._element.module = "CoreElementPlayEffect"
	self._element.values.operation = "fade_kill"
	self._element.values.elements = {}
end

function EditorStopEffect:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementPlayEffect"})
	self:ComboCtrl("operation", {"kill", "fade_kill"}, {help = "Select a kind of operation to perform on the added effects"})
end