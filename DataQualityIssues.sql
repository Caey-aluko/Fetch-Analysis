-- Orphaned Receipts (no linked user)
SELECT receipt_id FROM receipts
WHERE user_id NOT IN (SELECT user_id FROM users);

-- Receipt Items with Invalid Brand Codes
SELECT ri.* FROM receipt_items ri
LEFT JOIN brands b ON ri.brand_id = b.brand_id
WHERE b.brand_code IS NULL;

-- Mismatch in Purchased Item Count
SELECT r.receipt_id, 
       r.purchased_item_count, 
       COUNT(ri.receipt_item_id)
FROM receipts r
LEFT JOIN receipt_items ri ON r.receipt_id = ri.receipt_id
GROUP BY r.receipt_id
HAVING COUNT(ri.receipt_item_id) != r.purchased_item_count;