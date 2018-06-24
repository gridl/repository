context("selection")

test_that("filter adds up", {
  r <- many_repository()

  q <- filter(r, x == 1)
  expect_equal(quos_text(q$filter), "x == 1")

  q <- filter(q, y == 2)
  expect_equal(quos_text(q$filter), c("x == 1", "y == 2"))
})


test_that("arrange adds up", {
  r <- many_repository()

  q <- arrange(r, x)
  expect_equal(quos_text(q$arrange), "x")

  q <- arrange(q, y)
  expect_equal(quos_text(q$arrange), c("x", "y"))
})


test_that("select subsets", {
  r <- many_repository()

  q <- select(r, x, y)
  expect_equal(quos_text(q$select), c("x", "y"))

  q <- select(q, x)
  expect_equal(quos_text(q$select), "x")

  expect_error(select(q, y), "selection reduced to an empty set")
})


test_that("top_n chooses top n entries", {
  r <- many_repository()

  q <- top_n(r, 2)
  expect_equal(q$top, 2)

  expect_error(top_n(r, 0))
  expect_error(top_n(r, -1))
  expect_error(top_n(r, "a"))
  expect_error(top_n(r, 10, some_column))
})


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
  expect_named(x, c("object", "id", "class", "parent_commit", "parents", "time"),
               ignore.order = TRUE)
  expect_equal(nrow(x), 4)
})


test_that("filter by id", {
  r <- many_repository()

  x <- r %>% select(id) %>% filter(id == 'a') %>% execute
  expect_length(x, 1)
  expect_named(x, 'id')
  expect_equal(x$id, 'a')
})
