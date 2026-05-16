#
# Test Option-aware DataFrame joins with book/author datasets  
#
use std/assert
use ../../../../option/df

# ============================================================
# Test Data Creation Functions
# ============================================================

# Create synthetic books dataset (based on historical SQL examples)
# ┌─────────────┬──────────────┬───────────┐
# │   book_id   │  publisher   │  status   │
# ├─────────────┼──────────────┼───────────┤
# │ Some("B001")│ Some("NYP")  │ published │
# │ Some("B002")│ Some("LAP")  │ published │
# │ Some("B003")│     None     │  draft    │
# │ Some("B004")│ Some("NYP")  │  reprint  │
# └─────────────┴──────────────┴───────────┘
def create-books-data [] {
    [
        { book_id: {type: "some", value: "B001"}, publisher: {type: "some", value: "NYP"}, status: {type: "some", value: "published"} }
        { book_id: {type: "some", value: "B002"}, publisher: {type: "some", value: "LAP"}, status: {type: "some", value: "published"} }
        { book_id: {type: "some", value: "B003"}, publisher: {type: "none"}, status: {type: "some", value: "draft"} }
        { book_id: {type: "some", value: "B004"}, publisher: {type: "some", value: "NYP"}, status: {type: "some", value: "reprint"} }
    ]
}

# Create synthetic sales dataset  
# ┌─────────────┬─────────────────┬───────┐
# │   book_id   │   order_type    │ units │
# ├─────────────┼─────────────────┼───────┤
# │ Some("B001")│ Some("online")  │  85   │
# │ Some("B002")│ Some("store")   │  92   │
# │ Some("B005")│ Some("online")  │  78   │
# │ Some("B001")│ Some("bulk")    │  88   │
# └─────────────┴─────────────────┴───────┘
def create-sales-data [] {
    [
        { book_id: {type: "some", value: "B001"}, order_type: {type: "some", value: "online"}, units: {type: "some", value: 85} }
        { book_id: {type: "some", value: "B002"}, order_type: {type: "some", value: "store"}, units: {type: "some", value: 92} }
        { book_id: {type: "some", value: "B005"}, order_type: {type: "some", value: "online"}, units: {type: "some", value: 78} }
        { book_id: {type: "some", value: "B001"}, order_type: {type: "some", value: "bulk"}, units: {type: "some", value: 88} }
    ]
}

# Create dataset with some None values in join keys
# ┌─────────────┬──────────────┬───────┐
# │   book_id   │    genre     │ pages │
# ├─────────────┼──────────────┼───────┤
# │ Some("B001")│ Some("SF")   │  300  │
# │     None    │ Some("ROM")  │  250  │
# │ Some("B003")│     None     │  400  │
# └─────────────┴──────────────┴───────┘
def create-incomplete-data [] {
    [
        { book_id: {type: "some", value: "B001"}, genre: {type: "some", value: "SF"}, pages: {type: "some", value: 300} }
        { book_id: {type: "none"}, genre: {type: "some", value: "ROM"}, pages: {type: "some", value: 250} }
        { book_id: {type: "some", value: "B003"}, genre: {type: "none"}, pages: {type: "some", value: 400} }
    ]
}

# ============================================================
# Test Functions  
# ============================================================

# [test] inner join with realistic datasets
# Expected result: Books ∩ Sales on book_id
# ┌─────────────┬──────────────┬───────────┬─────────────────┬───────┐
# │   book_id   │  publisher   │  status   │   order_type    │ units │
# ├─────────────┼──────────────┼───────────┼─────────────────┼───────┤
# │ Some("B001")│ Some("NYP")  │ published │ Some("online")  │  85   │
# │ Some("B001")│ Some("NYP")  │ published │ Some("bulk")    │  88   │
# │ Some("B002")│ Some("LAP")  │ published │ Some("store")   │  92   │
# └─────────────┴──────────────┴───────────┴─────────────────┴───────┘
def test-option-join-inner [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | df join $sales book_id
    
    # Should have 3 matching records (B001 appears twice in sales)
    assert equal ($result | length) 3
    
    # Check that B001 has both online and bulk orders
    let b001_records = $result | where {|r| $r.book_id.value == "B001"}
    assert equal ($b001_records | length) 2
    
    # Verify merged data contains fields from both tables
    let first_record = $result | get 0
    assert ($first_record | columns | any {|c| $c == "status"})  # from books
    assert ($first_record | columns | any {|c| $c == "units"})   # from sales
}

# [test] left join preserves all left records
# Expected result: All books + matched sales (missing sales = None)
# ┌─────────────┬──────────────┬───────────┬─────────────────┬─────────┐
# │   book_id   │  publisher   │  status   │   order_type    │  units  │
# ├─────────────┼──────────────┼───────────┼─────────────────┼─────────┤
# │ Some("B001")│ Some("NYP")  │ published │ Some("online")  │   85    │
# │ Some("B001")│ Some("NYP")  │ published │ Some("bulk")    │   88    │
# │ Some("B002")│ Some("LAP")  │ published │ Some("store")   │   92    │
# │ Some("B003")│     None     │  draft    │      None       │  None   │
# │ Some("B004")│ Some("NYP")  │  reprint  │      None       │  None   │
# └─────────────┴──────────────┴───────────┴─────────────────┴─────────┘
def test-option-join-left [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | df join $sales book_id --left
    
    # Should have 5 records (4 books, with B001 appearing twice due to 2 sales)
    assert equal ($result | length) 5
    
    # B003 and B004 should have {type: "none"} for sales fields
    let b003 = $result | where {|r| $r.book_id.value == "B003"} | get 0
    assert equal $b003.units {type: "none"}
    assert equal $b003.order_type {type: "none"}
}

# [test] right join preserves all right records  
# Expected result: All sales + matched books (missing books = None)
# ┌─────────────┬──────────────┬───────────┬─────────────────┬───────┐
# │   book_id   │  publisher   │  status   │   order_type    │ units │
# ├─────────────┼──────────────┼───────────┼─────────────────┼───────┤
# │ Some("B001")│ Some("NYP")  │ published │ Some("online")  │  85   │
# │ Some("B002")│ Some("LAP")  │ published │ Some("store")   │  92   │
# │ Some("B005")│     None     │    None   │ Some("online")  │  78   │
# │ Some("B001")│ Some("NYP")  │ published │ Some("bulk")    │  88   │
# └─────────────┴──────────────┴───────────┴─────────────────┴───────┘
def test-option-join-right [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | df join $sales book_id --right
    
    # Should have 4 records (all sales, including B005 which has no book record)
    assert equal ($result | length) 4
    
    # B005 should have {type: "none"} for book fields
    let b005 = $result | where {|r| $r.units.value == 78} | get 0  # B005 has units 78
    assert equal $b005.status {type: "none"}
    assert equal $b005.publisher {type: "none"}
}

# [test] outer join includes all records from both sides
# Expected result: Union of all books and sales
# ┌─────────────┬──────────────┬───────────┬─────────────────┬─────────┐
# │   book_id   │  publisher   │  status   │   order_type    │  units  │
# ├─────────────┼──────────────┼───────────┼─────────────────┼─────────┤
# │ Some("B001")│ Some("NYP")  │ published │ Some("online")  │   85    │
# │ Some("B001")│ Some("NYP")  │ published │ Some("bulk")    │   88    │
# │ Some("B002")│ Some("LAP")  │ published │ Some("store")   │   92    │
# │ Some("B003")│     None     │  draft    │      None       │  None   │
# │ Some("B004")│ Some("NYP")  │  reprint  │      None       │  None   │
# │ Some("B005")│     None     │    None   │ Some("online")  │   78    │
# └─────────────┴──────────────┴───────────┴─────────────────┴─────────┘
def test-option-join-outer [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | df join $sales book_id --outer
    
    # Should have 6 records (B001: 2, B002: 1, B003: 1, B004: 1, B005: 1)
    assert equal ($result | length) 6
    
    # Verify we have records for all books and sales
    let book_ids = $result | get book_id | where {|id| $id.type == "some"} | get value | uniq
    assert (("B001" in $book_ids) and ("B002" in $book_ids) and ("B003" in $book_ids) and ("B004" in $book_ids))
    
    # B005 appears as a record with Some book_id from sales data
    let b005_record = $result | where {|r| $r.book_id.type == "some" and $r.book_id.value == "B005"}
    assert (($b005_record | length) == 1)
    assert (($b005_record | get 0 | get units.value) == 78)
}

# [test] join filters out records with None in join keys
# Books with None in join keys are filtered out during composite key creation
# Expected result: Only B001 matches (None values in keys excluded)
# ┌─────────────┬──────────────┬───────────┬──────────────┬───────┐
# │   book_id   │  publisher   │  status   │    genre     │ pages │
# ├─────────────┼──────────────┼───────────┼──────────────┼───────┤
# │ Some("B001")│ Some("NYP")  │ published │ Some("SF")   │  300  │
# └─────────────┴──────────────┴───────────┴──────────────┴───────┘
def test-option-join-none-filtering [] {
    let books = (create-books-data)
    let incomplete = (create-incomplete-data)
    
    let result = $books | df join $incomplete book_id
    
    # Should match B001 and B003 (B003 exists in both sides, even with None genre)
    # The None record (book_id: None) gets filtered out during key creation  
    assert equal ($result | length) 2
    
    let b001 = $result | where {|r| $r.book_id.value == "B001"} | get 0
    assert equal $b001.pages.value 300
    
    let b003 = $result | where {|r| $r.book_id.value == "B003"} | get 0  
    assert equal $b003.pages.value 400
}

# [test] multi-column joins work correctly  
# Join on [id, category] requires both columns to match
# Left Table:              Right Table:
# ┌────┬──────────┐        ┌────┬──────────┬───────┐
# │ id │ category │        │ id │ category │ score │
# ├────┼──────────┤        ├────┼──────────┼───────┤
# │ 1  │    A     │        │ 1  │    A     │  95   │
# │ 2  │    B     │        │ 1  │    C     │  88   │
# └────┴──────────┘        │ 2  │    B     │  76   │
#                          └────┴──────────┴───────┘
# Expected: Matches (1,A) and (2,B) = 2 records
def test-option-join-multi-column [] {
    let left = [
        { id: {type: "some", value: 1}, category: {type: "some", value: "A"}, data: {type: "some", value: "left1"} }
        { id: {type: "some", value: 2}, category: {type: "some", value: "B"}, data: {type: "some", value: "left2"} }
    ]
    
    let right = [
        { id: {type: "some", value: 1}, category: {type: "some", value: "A"}, score: {type: "some", value: 95} }
        { id: {type: "some", value: 1}, category: {type: "some", value: "C"}, score: {type: "some", value: 88} }
        { id: {type: "some", value: 2}, category: {type: "some", value: "B"}, score: {type: "some", value: 76} }
    ]
    
    let result = $left | df join $right id category
    
    # Should have 2 matching records (1,A) and (2,B)
    assert equal ($result | length) 2
    
    # Verify the correct records matched
    let record_1a = $result | where {|r| ($r.id.value == 1) and ($r.category.value == "A")} | get 0
    assert equal $record_1a.data.value "left1"
    assert equal $record_1a.score.value 95
}
