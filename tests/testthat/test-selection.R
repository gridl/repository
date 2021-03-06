context("selection")

# --- library ----------------------------------------------------------

test_that("symbol is matched", {
  s <- quote(id)

  expect_true(expr_match(quote(id), s))
  expect_true(expr_match(quote(id == 1), s))
  expect_true(expr_match(quote(f(id)), s))
  expect_true(expr_match(quote(f(id) == 1), s))
  expect_true(expr_match(quote(f(a, b, id ** 2) == 1), s))

  expect_false(expr_match(quote(f(id = 2)), s))
  expect_false(expr_match(quote(id(1)), s))
})


test_that("symbol in quos", {
  q <- list(rlang::quo(id == 1), rlang::quo(f(z)))

  expect_equal(quos_match(q, id), c(T, F))
  expect_equal(quos_match(q, "id"), c(T, F))
  expect_equal(quos_match(q, z), c(F, T))

  expect_equal(quos_match(q, a), c(F, F))
})


# --- tags -------------------------------------------------------------

known_tags <- c("artifact", "class", "names", "parent_commit", "parents", "time")


test_that("all tag names", {
  q <- as_query(many_repository())

  n <- all_tag_names(q)
  expect_equal(sort(n), known_tags)

  n <- q %>% filter(id == 'a') %>% all_tag_names
  expect_equal(sort(n), known_tags)
})


test_that("all tag values", {
  q <- as_query(many_repository())

  n <- all_tag_values(q)
  expect_named(n, known_tags, ignore.order = TRUE)
  expect_equal(n$names, letters[1:4])

  n <- q %>% filter(id == 'a') %>% all_tag_values
  expect_named(n, known_tags, ignore.order = TRUE)
  expect_equal(n$names, 'a')
})


# --- filter -----------------------------------------------------------

test_that("filter adds up", {
  r <- many_repository()

  q <- filter(r, x == 1)
  expect_equal(quos_text(q$filter), "x == 1")

  q <- filter(q, y == 2)
  expect_equal(quos_text(q$filter), c("x == 1", "y == 2"))
})


test_that("filter by id", {
  r <- many_repository()

  # no filter
  x <- r %>% select(id) %>% select_ids
  expect_equal(x, letters[1:4])

  # first special case
  x <- r %>% select(id) %>% filter(id == 'a') %>% select_ids
  expect_equal(x, 'a')

  # first special case: variable
  i <- 'a'
  x <- r %>% select(id) %>% filter(id == i) %>% select_ids
  expect_equal(x, 'a')

  # second special case
  x <- r %>% select(id) %>% filter(id %in% c('a', 'b')) %>% select_ids
  expect_equal(x, letters[1:2])

  # general case
  x <- r %>% select(id) %>% filter(id != 'a') %>% select_ids
  expect_equal(x, letters[2:4])
})


# --- arrange ----------------------------------------------------------

test_that("arrange adds up", {
  r <- many_repository()

  q <- arrange(r, x)
  expect_equal(quos_text(q$arrange), "x")

  q <- arrange(q, y)
  expect_equal(quos_text(q$arrange), c("x", "y"))
})


# --- select -----------------------------------------------------------

test_that("select subsets", {
  r <- many_repository()

  q <- select(r, time, id)
  expect_equivalent(q$select, c("time", "id"))

  q <- select(q, time)
  expect_equivalent(q$select, "time")

  expect_error(select(q, id), "select: selection reduced to an empty set")
})

test_that("various types of select", {
  r <- many_repository()

  # a single column
  x <- select(r, id) %>% execute
  expect_named(x, "id")
  expect_setequal(x$id, letters[1:4])

  # from character
  y <- select(r, "id") %>% execute
  expect_equal(x, y)

  # basically everything
  x <- select(r, -artifact) %>% execute
  expect_named(x, c("object", "id", "class", "names", "parent_commit", "parents", "time"),
               ignore.order = TRUE)
  expect_equal(nrow(x), 4)

  # only an actual tag
  y <- select(r, names) %>% execute
  expect_equal(y$names, letters[1:4])
})


test_that("no tag names for empty query", {
  r <- many_repository()

  q <- as_query(r)
  expect_length(all_select_names(q), 8)

  q <- filter(r, TRUE)
  expect_length(all_select_names(q), 8)

  q <- filter(r, FALSE)
  expect_length(all_select_names(q), 0)
})


# --- top_n ------------------------------------------------------------

test_that("top_n chooses top n entries", {
  r <- many_repository()

  q <- top_n(r, 2)
  expect_equal(q$top, 2)

  expect_error(top_n(r, 0))
  expect_error(top_n(r, -1))
  expect_error(top_n(r, "a"))
  expect_error(top_n(r, 10, some_column))
})


# --- summary ----------------------------------------------------------

test_that("summary is recorded", {
  r <- many_repository()

  q <- summarise(r, n = n())
  expect_length(q$summarise, 1)

  x <- select(q, id) %>% execute
  expect_named(x, 'n')
  expect_equal(x$n, 4)
})


test_that("simple summary", {
  r <- many_repository()

  q <- select(r, id) %>% summarise(id = min(id), n = n()) %>% execute
  expect_length(q, 2)
  expect_named(q, c("id", "n"))
  expect_equal(q$id, 'a')
  expect_equal(q$n, 4L)
})


# --- execute ----------------------------------------------------------

test_that("execute runs the query", {
  r <- many_repository()

  x <- select(r, id) %>% execute
  expect_named(x, "id")
  expect_length(x$id, 4)
  expect_equal(x$id, letters[1:4])

  x <- select(r, id) %>% filter(class == "integer") %>% execute
  expect_equal(x$id, "b")
  x <- select(r, id) %>% filter(class == "numeric") %>% execute
  expect_equal(x$id, c("a", "c"))

  x <- select(r, id) %>% filter(class == "numeric") %>% arrange(desc(id)) %>% execute
  expect_equal(x$id, c("c", "a"))

  x <- select(r, id) %>% arrange(id) %>% top_n(1) %>% execute
  expect_equal(x$id, "a")
  x <- select(r, id) %>% arrange(desc(id)) %>% top_n(1) %>% execute
  expect_equal(x$id, "d")
})


test_that("simplify tags", {
  r <- flatten_lists(list(x = list(1, 2, 3), y = list(1, NULL, 2)))
  expect_named(r, c("x", "y"))
  expect_equal(r$x, 1:3)
  expect_equal(r$y, c(1, NA_real_, 2))

  r <- flatten_lists(list(x = 1:4, y = list(c(1L, 2L), NULL, 3L, 4L)))
  expect_named(r, c("x", "y"))
  expect_equal(r$x, 1:4)
  expect_equal(r$y, list(1:2, NA_integer_, 3L, 4L))

  tm <- as.POSIXct(1:10, origin = '1970-01-01')
  r <- flatten_lists(list(x = as.list(tm)))
  expect_named(r, 'x')
  expect_equal(r$x, tm)
})

# --- update -----------------------------------------------------------

test_that("update", {
  r <- many_repository()
  q <- filter(r, id == 'a')

  expect_tag <- function (tag, value) {
    expect_equal(nth(storage::os_read_tags(r$store, 'a'), tag), value, label = tag)
  }

  q %>% update(class = 'xyz')
  expect_tag('class', 'xyz')

  q %>% update(append(names, 'new_name'))
  expect_tag('names', c('a', 'new_name'))

  q %>% update(remove(names, 'new_name'))
  expect_tag('names', 'a')

  q %>% update(append(collections, 'new_col'))
  expect_tag('collections', 'new_col')
})


