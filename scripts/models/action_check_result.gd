# ============================================================
# ActionCheckResult - 行动合法性检查结果
# ============================================================
# 类型: RefCounted（纯数据）
#
# 用于行动前合法性检查的返回值，携带通过/失败状态和原因。
# 设计依据: docs/GAME_DESIGN_AGENT.md §8.3
# ============================================================
class_name ActionCheckResult
extends RefCounted


# ──────────────────────────────────────────
# 属性
# ──────────────────────────────────────────
var is_valid: bool = false
var reason: String = ""


# ──────────────────────────────────────────
# 静态工厂方法
# ──────────────────────────────────────────

## 创建"通过"结果
static func ok() -> ActionCheckResult:
	var result := ActionCheckResult.new()
	result.is_valid = true
	result.reason = ""
	return result


## 创建"失败"结果
## @param reason: 失败原因（人类可读）
static func fail(reason: String) -> ActionCheckResult:
	var result := ActionCheckResult.new()
	result.is_valid = false
	result.reason = reason
	return result


func _to_string() -> String:
	if is_valid:
		return "ActionCheckResult(OK)"
	else:
		return "ActionCheckResult(FAIL: %s)" % reason
