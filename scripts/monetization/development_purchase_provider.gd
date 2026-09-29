class_name DevelopmentPurchaseProvider
extends PurchaseProvider

var fail_next := false

func purchase(product_id: String) -> bool:
	if fail_next:
		fail_next = false
		return false
	return MonetizationData.PRODUCTS.has(product_id)

func restore(entitlements: Dictionary) -> Dictionary:
	return entitlements.duplicate(true)
