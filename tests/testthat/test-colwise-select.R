context("colwise select")

df <- tibble(x = 0L, y = 0.5, z = 1)

test_that("can select/rename all variables", {
  expect_identical(select_all(df), df)
  expect_error(
    rename_all(df),
    "`.funs` must specify a renaming function",
    fixed = TRUE
  )

  expect_identical(select_all(df, toupper), set_names(df, c("X", "Y", "Z")))
  expect_identical(select_all(df, toupper), rename_all(df, toupper))
})

test_that("can select/rename with predicate", {
  expect_identical(select_if(df, is_integerish), select(df, x, z))
  expect_error(
    rename_if(df, is_integerish),
    "`.funs` must specify a renaming function",
    fixed = TRUE
  )

  expect_identical(select_if(df, is_integerish, toupper), set_names(df[c("x", "z")], c("X", "Z")))
  expect_identical(rename_if(df, is_integerish, toupper), set_names(df, c("X", "y", "Z")))
})

test_that("can supply funs()", {
  scoped_lifecycle_silence()
  expect_identical(select_if(df, funs(is_integerish(.)), funs(toupper(.))), set_names(df[c("x", "z")], c("X", "Z")))
  expect_identical(rename_if(df, funs(is_integerish(.)), funs(toupper(.))), set_names(df, c("X", "y", "Z")))

  expect_identical(select_if(df, list(~is_integerish(.)), list(~toupper(.))), set_names(df[c("x", "z")], c("X", "Z")))
  expect_identical(rename_if(df, list(~is_integerish(.)), list(~toupper(.))), set_names(df, c("X", "y", "Z")))
})

test_that("fails when more than one renaming function is supplied", {
  scoped_lifecycle_silence()
  expect_error(
    select_all(df, funs(tolower, toupper)),
    "`.funs` must contain one renaming function, not 2",
    fixed = TRUE
  )
  expect_error(
    rename_all(df, funs(tolower, toupper)),
    "`.funs` must contain one renaming function, not 2",
    fixed = TRUE
  )

  expect_error(
    select_all(df, list(tolower, toupper)),
    "`.funs` must contain one renaming function, not 2",
    fixed = TRUE
  )
  expect_error(
    rename_all(df, list(tolower, toupper)),
    "`.funs` must contain one renaming function, not 2",
    fixed = TRUE
  )
})

test_that("can select/rename with vars()", {
  expect_identical(select_at(df, vars(x:y)), df[-3])
  expect_error(
    rename_at(df, vars(x:y)),
    "`.funs` must specify a renaming function",
    fixed = TRUE
  )

  expect_identical(select_at(df, vars(x:y), toupper), set_names(df[-3], c("X", "Y")))
  expect_identical(rename_at(df, vars(x:y), toupper), set_names(df, c("X", "Y", "z")))
})

test_that("select variants can use grouping variables (#3351, #3480)", {
  tbl <- tibble(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)

  expect_identical(
    select(tbl, gr1),
    select_at(tbl, vars(gr1))
  )
  expect_identical(
    select_all(tbl),
    tbl
  )
  expect_identical(
    select_if(tbl, is.integer),
    tbl
  )
})

test_that("select_if keeps grouping cols", {
  expect_silent(df <- iris %>% group_by(Species) %>% select_if(is.numeric))
  expect_equal(df, tbl_df(iris[c(5, 1:4)]))
})

test_that("select_if() handles non-syntactic colnames", {
  df <- tibble(`x 1` = 1:3)
  expect_identical(select_if(df, is_integer)[[1]], 1:3)
})

test_that("select_if() handles quoted predicates", {
  expected <- select_if(mtcars, is_integerish)
  expect_identical(select_if(mtcars, "is_integerish"), expected)
  expect_identical(select_if(mtcars, ~ is_integerish(.x)), expected)
})

test_that("rename_all() works with grouped data (#3363)", {
  df <- data.frame(a = 1, b = 2)
  out <- df %>% group_by(a) %>% rename_all(toupper)
  expect_identical(out, group_by(data.frame(A = 1, B = 2), A))
})

test_that("scoping (#3426)", {
  interface <- function(.tbl, .funs = list()) {
    impl(.tbl, .funs = .funs)
  }

  impl <- function(.tbl, ...) {
    select_all(.tbl, ...)
  }

  expect_identical(
    interface(mtcars, .funs = toupper),
    select_all(mtcars, .funs = list(toupper))
  )
})

test_that("rename variants can rename a grouping variable (#3351)", {
  tbl <- tibble(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)
  res <- rename(tbl, GR1 = gr1, GR2 = gr2, X = x)

  expect_identical(
    rename_at(tbl, vars(everything()), toupper),
    res
  )

  expect_identical(
    rename_all(tbl, toupper),
    res
  )

  expect_identical(
    rename_if(tbl, is.integer, toupper),
    res
  )
})

test_that("select_all does not change the order of columns (#3351)", {
  tbl <- group_by(tibble(x = 1:4, y = 1:4), y)
  expect_identical(select_all(tbl), tbl)

  tbl <- group_by(tibble(x = 1:4, y = 1:4), x)
  expect_identical(select_all(tbl), tbl)

  tbl <- group_by(tibble(x = 1:4, y = 1:4, z = 1:4), y)
  expect_identical(select_all(tbl), tbl)
})

test_that("mutate_all does not change the order of columns (#3351)", {
  tbl <- group_by(tibble(x = 1:4, y = 1:4), y)
  expect_message(expect_identical(names(mutate_all(tbl, identity)), names(tbl)), "ignored")

  tbl <- group_by(tibble(x = 1:4, y = 1:4), x)
  expect_message(expect_identical(names(mutate_all(tbl, identity)), names(tbl)), "ignored")

  tbl <- group_by(tibble(x = 1:4, y = 1:4, z = 1:4), y)
  expect_message(expect_identical(names(mutate_all(tbl, identity)), names(tbl)), "ignored")
})

test_that("select_if() and rename_if() handles logical (#4213)", {
  ids <- "Sepal.Length"
  expect_identical(
    iris %>% select_if(!names(.) %in% ids),
    iris %>% select(-Sepal.Length)
  )

  expect_identical(
    iris %>% rename_if(!names(.) %in% ids, toupper),
    iris %>% rename_at(setdiff(names(.), "Sepal.Length"), toupper)
  )

})

test_that("rename_at() handles empty selection (#4324)", {
  expect_identical(
    mtcars %>% rename_at(vars(contains("fake_col")),~paste0("NewCol.",.)),
    mtcars
  )
})

test_that("rename_all/at() call the function with simple character vector (#4459)", {
  fun <- function(x) case_when(x == 'mpg' ~ 'fuel_efficiency', TRUE ~ x)
  out <- rename_all(mtcars,fun)
  expect_equal(names(out)[1L], 'fuel_efficiency')

  out <- rename_at(mtcars, vars(everything()), fun)
  expect_equal(names(out)[1L], 'fuel_efficiency')
})
