#
# Test DataFrame joins with book/author datasets (standard joins only)
# For Option-aware joins, see option/df/join/test/
#
use std/assert
use ../../../df/join *

# ============================================================
# Test Data Creation Functions
# ============================================================

# Create synthetic books dataset (based on historical SQL examples)
# ┌─────────┬───────────┬───────────┐
# │ book_id │ publisher │  status   │
# ├─────────┼───────────┼───────────┤
# │  "B001" │   "NYP"   │ published │
# │  "B002" │   "LAP"   │ published │
# │  "B003" │    null   │   draft   │
# │  "B004" │   "NYP"   │  reprint  │
# └─────────┴───────────┴───────────┘
def create-books-data [] {
    [
        { book_id: "B001", publisher: "NYP", status: "published" }
        { book_id: "B002", publisher: "LAP", status: "published" }
        { book_id: "B003", publisher: null, status: "draft" }
        { book_id: "B004", publisher: "NYP", status: "reprint" }
    ]
}

# Create synthetic sales dataset  
# ┌─────────┬────────────┬───────┐
# │ book_id │ order_type │ units │
# ├─────────┼────────────┼───────┤
# │ "B001"  │  "online"  │  85   │
# │ "B002"  │  "store"   │  92   │
# │ "B005"  │  "online"  │  78   │
# │ "B001"  │  "bulk"    │  88   │
# └─────────┴────────────┴───────┘
def create-sales-data [] {
    [
        { book_id: "B001", order_type: "online", units: 85 }
        { book_id: "B002", order_type: "store", units: 92 }
        { book_id: "B005", order_type: "online", units: 78 }
        { book_id: "B001", order_type: "bulk", units: 88 }
    ]
}

# Create dataset with some null values in join keys
# ┌─────────┬─────────┬───────┐
# │ book_id │  genre  │ pages │
# ├─────────┼─────────┼───────┤
# │ "B001"  │  "SF"   │  300  │
# │  null   │ "ROM"   │  250  │
# │ "B003"  │  null   │  400  │
# └─────────┴─────────┴───────┘
def create-incomplete-data [] {
    [
        { book_id: "B001", genre: "SF", pages: 300 }
        { book_id: null, genre: "ROM", pages: 250 }
        { book_id: "B003", genre: null, pages: 400 }
    ]
}

# ============================================================
# Test Functions  
# ============================================================

# [test] inner join with realistic datasets
# Expected result: Books ∩ Sales on book_id
# ┌─────────┬───────────┬───────────┬────────────┬───────┐
# │ book_id │ publisher │  status   │ order_type │ units │
# ├─────────┼───────────┼───────────┼────────────┼───────┤
# │ "B001"  │   "NYP"   │ published │  "online"  │  85   │
# │ "B001"  │   "NYP"   │ published │  "bulk"    │  88   │
# │ "B002"  │   "LAP"   │ published │  "store"   │  92   │
# └─────────┴───────────┴───────────┴────────────┴───────┘
def "test join inner basic" [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | join $sales book_id
    
    # Should have 3 matching records (B001 appears twice in sales)
    assert equal ($result | length) 3
    
    # Check that B001 has both online and bulk orders
    let b001_records = $result | where book_id == "B001"
    assert equal ($b001_records | length) 2
    
    # Verify merged data contains fields from both tables
    let first_record = $result | get 0
    assert ("status" in ($first_record | columns))  # from books
    assert ("units" in ($first_record | columns))   # from sales
}

# [test] left join preserves all left records
# Expected result: All books + matched sales (missing sales = null)
# ┌─────────┬───────────┬───────────┬────────────┬───────┐
# │ book_id │ publisher │  status   │ order_type │ units │
# ├─────────┼───────────┼───────────┼────────────┼───────┤
# │ "B001"  │   "NYP"   │ published │  "online"  │  85   │
# │ "B001"  │   "NYP"   │ published │  "bulk"    │  88   │
# │ "B002"  │   "LAP"   │ published │  "store"   │  92   │
# │ "B003"  │    null   │   draft   │    null    │ null  │
# │ "B004"  │   "NYP"   │  reprint  │    null    │ null  │
# └─────────┴───────────┴───────────┴────────────┴───────┘
def "test join left" [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | join $sales book_id --left
    
    # Should have 5 records (4 books, with B001 appearing twice due to 2 sales)
    assert equal ($result | length) 5
    
    # B003 and B004 should have null for sales fields
    let b003 = $result | where book_id == "B003" | get 0
    assert equal $b003.units null
    assert equal $b003.order_type null
}

# [test] right join preserves all right records  
# Expected result: All sales + matched books (missing books = null)
# ┌─────────┬───────────┬───────────┬────────────┬───────┐
# │ book_id │ publisher │  status   │ order_type │ units │
# ├─────────┼───────────┼───────────┼────────────┼───────┤
# │ "B001"  │   "NYP"   │ published │  "online"  │  85   │
# │ "B002"  │   "LAP"   │ published │  "store"   │  92   │
# │ "B005"  │    null   │    null   │  "online"  │  78   │
# │ "B001"  │   "NYP"   │ published │  "bulk"    │  88   │
# └─────────┴───────────┴───────────┴────────────┴───────┘
def "test join right" [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | join $sales book_id --right
    
    # Should have 4 records (all sales, including B005 which has no book record)
    assert equal ($result | length) 4
    
    # B005 should have null for book fields
    let b005 = $result | where units == 78 | get 0  # B005 has units 78
    assert equal $b005.status null
    assert equal $b005.publisher null
}

# [test] outer join includes all records from both sides
# Expected result: Union of all books and sales
# ┌─────────┬───────────┬───────────┬────────────┬───────┐
# │ book_id │ publisher │  status   │ order_type │ units │
# ├─────────┼───────────┼───────────┼────────────┼───────┤
# │ "B001"  │   "NYP"   │ published │  "online"  │  85   │
# │ "B001"  │   "NYP"   │ published │  "bulk"    │  88   │
# │ "B002"  │   "LAP"   │ published │  "store"   │  92   │
# │ "B003"  │    null   │   draft   │    null    │ null  │
# │ "B004"  │   "NYP"   │  reprint  │    null    │ null  │
# │ "B005"  │    null   │    null   │  "online"  │  78   │
# └─────────┴───────────┴───────────┴────────────┴───────┘
def "test join outer" [] {
    let books = (create-books-data)
    let sales = (create-sales-data)
    
    let result = $books | join $sales book_id --outer
    
    # Should have 6 records (B001: 2, B002: 1, B003: 1, B004: 1, B005: 1)
    assert equal ($result | length) 6
    
    # Verify we have records for all books and sales
    let book_ids = $result | get book_id | where $it != null | uniq
    assert ("B001" in $book_ids)
    assert ("B002" in $book_ids)
    assert ("B003" in $book_ids)
    assert ("B004" in $book_ids)
    
    # B005 appears as a record with book_id from sales data
    let b005_record = $result | where book_id == "B005"
    assert (($b005_record | length) == 1)
    assert (($b005_record | get 0 | get units) == 78)
}

# [test] multi-column joins work correctly  
# Join on [book_id, category] requires both columns to match
# Left Table:                    Right Table:
# ┌─────────┬──────────┐        ┌─────────┬──────────┬───────┐
# │ book_id │ category │        │ book_id │ category │ score │
# ├─────────┼──────────┤        ├─────────┼──────────┼───────┤
# │ "B001"  │    "A"   │        │ "B001"  │    "A"   │  95   │
# │ "B002"  │    "B"   │        │ "B001"  │    "C"   │  88   │
# └─────────┴──────────┘        │ "B002"  │    "B"   │  76   │
#                               └─────────┴──────────┴───────┘
# Expected: Matches (B001,A) and (B002,B) = 2 records
def "test join multi column" [] {
    let left = [
        { book_id: "B001", category: "A", data: "left1" }
        { book_id: "B002", category: "B", data: "left2" }
    ]
    
    let right = [
        { book_id: "B001", category: "A", score: 95 }
        { book_id: "B001", category: "C", score: 88 }
        { book_id: "B002", category: "B", score: 76 }
    ]
    
    let result = $left | join $right book_id category
    
    # Should have 2 matching records (B001,A) and (B002,B)
    assert equal ($result | length) 2
    
    # Verify the correct records matched
    let record_b001a = $result | where book_id == "B001" and category == "A" | get 0
    assert equal $record_b001a.data "left1"
    assert equal $record_b001a.score 95
}

# [test] single column join (common case)
# Authors table joined with Books table on author_id
# Authors:                     Books:
# ┌───────────┬─────────┐      ┌───────────┬─────────────┐
# │ author_id │  name   │      │ author_id │    title    │
# ├───────────┼─────────┤      ├───────────┼─────────────┤
# │     1     │ "Alice" │      │     1     │ "Dune Pt1" │
# │     2     │ "Bob"   │      │     2     │ "1984"      │
# └───────────┴─────────┘      └───────────┴─────────────┘
def "test join single column" [] {
    let authors = [
        { author_id: 1, name: "Alice" }
        { author_id: 2, name: "Bob" }
    ]
    
    let books = [
        { author_id: 1, title: "Dune Pt1" }
        { author_id: 2, title: "1984" }
    ]
    
    let result = $authors | join $books author_id --inner
    
    assert equal ($result | length) 2
    assert equal ($result | get 0 | get title) "Dune Pt1"
}

# [test] error handling - empty columns
def "test join error empty columns" [] {
    let books = [{ book_id: "B001", title: "Dune" }]
    let sales = [{ book_id: "B001", units: 100 }]
    
    assert error { $books | join $sales }
}

# [test] error handling - invalid join type
def "test join error invalid join type" [] {
    let books = [{ book_id: "B001", title: "Dune" }]
    let sales = [{ book_id: "B001", units: 100 }]
    
    assert error { $books | join $sales book_id --inner --left }
}

# [test] inner join explicitly specified
def "test join inner explicit" [] {
    let books = [{ book_id: "B001", title: "Dune", genre: "SF" }]
    let reviews = [{ book_id: "B001", genre: "SF", rating: 5 }]
    
    let result = $books | join $reviews book_id genre --inner
    
    assert equal ($result | length) 1
    assert equal ($result | get 0 | get rating) 5
}

# [test] left join explicitly specified
def "test join left explicit" [] {
    let books = [
        { book_id: "B001", title: "Dune", genre: "SF" }
        { book_id: "B002", title: "1984", genre: "Dystopian" }
    ]
    let reviews = [{ book_id: "B001", genre: "SF", rating: 5 }]
    
    let result = $books | join $reviews book_id genre --left
    
    assert equal ($result | length) 2
    assert equal ($result | get 0 | get rating) 5
    assert equal ($result | get 1 | get rating) null
}

# [test] mixed data types in join keys
# Book ratings (int) and scores (float) can be used as composite keys
# Books:                           Scores:
# ┌─────────┬────────┬─────────┐  ┌─────────┬────────┬───────┐
# │ book_id │ rating │ category │  │ book_id │ rating │ bonus │
# ├─────────┼────────┼─────────┤  ├─────────┼────────┼───────┤
# │   1     │  95.5  │ premium │  │   1     │  95.5  │  100  │
# │   2     │  80.0  │ standard│  │   2     │  80.0  │   50  │
# └─────────┴────────┴─────────┘  └─────────┴────────┴───────┘
def "test join mixed data types" [] {
    let books = [
        { book_id: 1, rating: 95.5, category: "premium" }
        { book_id: 2, rating: 80.0, category: "standard" }
    ]
    
    let scores = [
        { book_id: 1, rating: 95.5, bonus: 100 }
        { book_id: 2, rating: 80.0, bonus: 50 }
    ]
    
    let result = $books | join $scores book_id rating --inner
    
    assert equal ($result | length) 2
    assert equal ($result | get 0 | get bonus) 100
}

# [test] join filters out records with null in join keys
# Books with null in join keys are filtered out during composite key creation
# Expected result: Only B001 matches (null values in keys excluded)
# ┌─────────┬───────────┬───────────┬─────────┬───────┐
# │ book_id │ publisher │  status   │  genre  │ pages │
# ├─────────┼───────────┼───────────┼─────────┼───────┤
# │ "B001"  │   "NYP"   │ published │  "SF"   │  300  │
# └─────────┴───────────┴───────────┴─────────┴───────┘
def "test join null filtering" [] {
    let books = (create-books-data)
    let incomplete = (create-incomplete-data)
    
    let result = $books | join $incomplete book_id
    
    # Should match B001 only (B003 has null genre, null book_id record filtered out)
    # Note: B003 exists in both sides but has null genre, which doesn't affect join on book_id  
    assert equal ($result | length) 2
    
    let b001 = $result | where book_id == "B001" | get 0
    assert equal $b001.pages 300
    
    let b003 = $result | where book_id == "B003" | get 0  
    assert equal $b003.pages 400
}

# [test] no duplicate columns in result
# When books and authors share column names, join keys appear once
# Books:                        Authors:
# ┌─────────┬────────┬───────┐  ┌─────────┬────────┬────────┐
# │ book_id │  name  │ pages │  │ book_id │  name  │ awards │
# ├─────────┼────────┼───────┤  ├─────────┼────────┼────────┤
# │ "B001"  │ "Dune" │  300  │  │ "B001"  │ "Dune" │   5    │
# └─────────┴────────┴───────┘  └─────────┴────────┴────────┘
# Result: book_id, name, pages, awards (no duplicates)
def "test join no duplicate columns" [] {
    let books = [{ book_id: "B001", name: "Dune", pages: 300 }]
    let authors = [{ book_id: "B001", name: "Dune", awards: 5 }]
    
    let result = $books | join $authors book_id name --inner
    
    # Should have book_id, name, pages, awards - no duplicates
    let columns = ($result | columns)
    assert equal ($columns | length) 4
    assert ("book_id" in $columns)
    assert ("name" in $columns)
    assert ("pages" in $columns)
    assert ("awards" in $columns)
}

# [test] left join with null in single key preserves key column
# Left table has row with null join key, which should be preserved with null value
# Left:                        Right:
# ┌────┬──────┬───────┐        ┌──────┬──────────┐
# │ id │ type │ value │        │ type │ category │
# ├────┼──────┼───────┤        ├──────┼──────────┤
# │ 1  │ "A"  │  10   │        │ "A"  │  "cat1"  │
# │ 2  │ null │  20   │        │ "C"  │  "cat3"  │
# │ 3  │ "C"  │  30   │        └──────┴──────────┘
# └────┴──────┴───────┘
# Expected: 3 rows, row with id=2 has type=null (column exists)
def "test join left null single key" [] {
    let left = [
        {id: 1, type: "A", value: 10}
        {id: 2, type: null, value: 20}
        {id: 3, type: "C", value: 30}
    ]

    let right = [
        {type: "A", category: "cat1"}
        {type: "C", category: "cat3"}
    ]

    let result = ($left | join $right type --left)

    # Should preserve all 3 left rows
    assert equal ($result | length) 3

    # Critical: row with null type must have 'type' column present
    let null_type_row = ($result | where id == 2 | get 0)
    assert ("type" in ($null_type_row | columns))
    assert equal $null_type_row.type null
    assert equal $null_type_row.value 20
    assert equal $null_type_row.category null
}

# [test] left join with null in multi-key preserves all key columns
# Left table has rows with null in one of multiple join keys
# Left:                                Right:
# ┌────┬──────┬──────┬───────┐        ┌──────┬──────┬──────────┐
# │ id │ key1 │ key2 │ value │        │ key1 │ key2 │ category │
# ├────┼──────┼──────┼───────┤        ├──────┼──────┼──────────┤
# │ 1  │ "A"  │ "X"  │  10   │        │ "A"  │ "X"  │  "cat1"  │
# │ 2  │ "B"  │ null │  20   │        └──────┴──────┴──────────┘
# │ 3  │ null │ "Z"  │  30   │
# └────┴──────┴──────┴───────┘
# Expected: 3 rows, rows with id=2,3 have null keys but columns exist
def "test join left null multi key" [] {
    let left = [
        {id: 1, key1: "A", key2: "X", value: 10}
        {id: 2, key1: "B", key2: null, value: 20}
        {id: 3, key1: null, key2: "Z", value: 30}
    ]

    let right = [
        {key1: "A", key2: "X", category: "cat1"}
    ]

    let result = ($left | join $right key1 key2 --left)

    # Should preserve all 3 left rows
    assert equal ($result | length) 3

    # Check row with null key2
    let null_key2_row = ($result | where id == 2 | get 0)
    assert ("key1" in ($null_key2_row | columns))
    assert ("key2" in ($null_key2_row | columns))
    assert equal $null_key2_row.key1 "B"
    assert equal $null_key2_row.key2 null

    # Check row with null key1
    let null_key1_row = ($result | where id == 3 | get 0)
    assert ("key1" in ($null_key1_row | columns))
    assert ("key2" in ($null_key1_row | columns))
    assert equal $null_key1_row.key1 null
    assert equal $null_key1_row.key2 "Z"
}
