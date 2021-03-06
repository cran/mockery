testthat::context('stub')

a = 10
f = function(x) x
g = function(x) f(x) + a
test_that('stubs function with return value', {
    # before stubbing
    expect_equal(g(20), 30)

    # when
    stub(g, 'f', 100)

    # then
    expect_equal(g(20), 110)
})

test_that('values restored after test', {
    expect_equal(f(15), 15)
    expect_equal(g(15), 25)
})

test_that('stubs function with function', {
    # given
    a = 10
    f = function(x) x
    g = function(x) f(x) + a

    # before stubbing
    expect_equal(g(20), 30)

    # when
    stub(g, 'f', function(...) 500)

    # then
    expect_equal(g(10), 510)
})


test_that('stubs function from namespace', {
    # given
    f = function() testthat::capture_output(print('hello'))

    # before stubbing
    expect_true(grepl('hello', f()))

    # when
    stub(f, 'testthat::capture_output', 10)

    # then
    expect_equal(f(), 10)
})

test_that('does not stub other namespeaced functions', {
    # given
    f = function() {
        a = testthat::capture_output(print('hello'))
        b = testthat::is_null('not null')
        return(c(a, b))
    }

    # when
    stub(f, 'testthat::is_null', 'stubbed output')

    # then
    result = f()
    expect_true(grepl('hello', result[1]))
    expect_equal(result[2], 'stubbed output')
})

test_that('stub multiple functions', {
    # given
    f = function(x) x + 10
    g = function(y) y + 20
    h = function(z) f(z) + g(z)

    # when
    stub(h, 'f', 300)
    stub(h, 'g', 500)

    # then
    expect_equal(h(1), 800)
})

test_that('stub multiple namespaced functions', {
    # given
    h = function(x) mockery::stub(x) + mockery::get_function_source(x)

    # when
    stub(h, 'mockery::stub', 300)
    stub(h, 'mockery::get_function_source', 500)

    # then
    expect_equal(h(1), 800)
})

test_that('stub works with do.call', {
    # given
    f = function(x) x + 10
    g = function(x) do.call('f', list(x))

    # before stub
    expect_equal(g(10), 20)

    # stub
    stub(g, 'f', 100)

    # then
    expect_equal(g(10), 100)
})

test_that('stub works with lapply', {
    # given
    f = function(x) x + 10
    g = function(x) lapply(x, 'f')
    l = list(1, 2, 3)

    # before stub
    expect_equal(g(l), list(11, 12, 13))

    # stub
    stub(g, 'f', 100)

    # then
    expect_equal(g(l), list(100, 100, 100))
})

test_that('stub works well with mock object', {
    # given
    f = function(x) x + 10
    g = function(x) f(x)

    mock_object = mock(100)
    stub(g, 'f', mock_object)

    # when
    result = g(5)

    # then
    expect_equal(result, 100)
})

f = function(x) x + 10
g = function(x) f(x)
test_that('mock object returns value', {
    mock_object = mock(1)
    stub(g, 'f', mock_object)

    expect_equal(g('anything'), 1)
    expect_called(mock_object, 1)
    expect_args(mock_object, 1, 'anything')
})

test_that('mock object multiple return values', {
    mock_object = mock(1, "a", sqrt(3))
    stub(g, 'f', mock_object)

    expect_equal(g('anything'), 1)
    expect_equal(g('anything'), "a")
    expect_equal(g('anything'), sqrt(3))
})

test_that('mock object accessing values of arguments', {
    mock_object <- mock()
    mock_object(x = 1)
    mock_object(y = 2)

    expect_equal(length(mock_object), 2)
    args <- mock_args(mock_object)

    expect_equal(args[[1]], list(x = 1))
    expect_equal(args[[2]], list(y = 2))
})

test_that('mock object accessing call expressions', {
    mock_object <- mock()
    mock_object(x = 1)
    mock_object(y = 2)

    expect_equal(length(mock_object), 2)
    calls <- mock_calls(mock_object)

    expect_equal(calls[[1]], quote(mock_object(x = 1)))
    expect_equal(calls[[2]], quote(mock_object(y = 2)))
})

library(R6)

some_other_class = R6Class("some_class",
    public = list(
        external_method = function() {return('this is external output')}
    )
)

some_class = R6Class("some_class",
    public = list(
        some_method = function() {return(some_function())},
        some_method_prime = function() {return(some_function())},
        other_method = function() {return('method in class')},
        method_without_other = function() { self$other_method() },
        method_with_other = function() {
          other <- some_other_class$new()
          other$external_method()
          self$other_method()
        }
    )
)

# Calling function from R6 method
 some_function = function() {return("called from within class")}
 obj = some_class$new()
test_that('stub works with R6 methods', {
    stub(obj$some_method, 'some_function', 'stub has been called')
    expect_equal(obj$some_method(), 'stub has been called')
})

test_that('stub works with R6 methods that call internal methods in them', {
    stub(obj$method_without_other, 'self$other_method', 'stub has been called')
    expect_equal(obj$method_without_other(), 'stub has been called')
})

test_that('stub works with R6 methods that have other objects in them', {
    stub(obj$method_with_other, 'self$other_method', 'stub has been called')
    expect_equal(obj$method_with_other(), 'stub has been called')
})

test_that('R6 method does not stay stubbed', {
    expect_equal(obj$some_method(), 'called from within class')
})

# Calling R6 method from function
other_func = function() {
    obj = some_class$new()
    return(obj$other_method())
}
test_that('stub works for stubbing R6 methods from within function calls', {
    stub(other_func, 'obj$other_method', 'stubbed R6 method')
    expect_equal(other_func(), 'stubbed R6 method')
})

test_that('stub does not stay in effect', {
    expect_equal(other_func(), 'method in class')
})

test_that('stub out of namespaced functions', {
    expect_true(grepl('hello', testthat::capture_output(print('hello'))))
    stub(testthat::capture_output, 'paste0', 'stubbed function')
    expect_equal(testthat::capture_output(print('hello')), 'stubbed function')
})

test_that('stub multiple namespaced and R6 functions from within test env', {
    stub(testthat::capture_output, 'paste0', 'stub 1')
    stub(obj$some_method, 'some_function', 'stub 2')
    stub(obj$some_method_prime, 'some_function', 'stub 3')
    stub(testthat::test_that, 'test_code', 'stub 4')

    # all stubs are active
    expect_equal(testthat::capture_output(print('hello')), 'stub 1')
    expect_equal(obj$some_method(), 'stub 2')
    expect_equal(obj$some_method_prime(), 'stub 3')
    expect_equal(testthat::test_that('a', print), 'stub 4')

    # non mocked R6 and namespaced functions work as expected
    expect_equal(obj$other_method(), 'method in class')
    testthat::expect_failure(expect_equal(4, 5))
})

h = function(x) 'called h'
g = function(x) h(x)
f = function(x) g(x)
test_that('use can specify depth of mocking', {
    stub_string = 'called stub!'
    stub(f, 'h', stub_string, depth=2)
    expect_equal(f(1), stub_string)
})

h = function(x) 'called h'
g = function(x) h(x)
f = function(x) paste0(h(x), g(x))
test_that('mocked function is mocked at all depths', {
    stub_string = 'called stub!'
    stub(f, 'h', stub_string, depth=2)
    expect_equal(f(1), 'called stub!called stub!')
})

h = function(x) 'called h'
g = function(x) h(x)
r = function(x) g(x)
f = function(x) paste0(h(x), r(x))
test_that('mocked function is mocked at all depths', {
    stub_string = 'called stub!'
    stub(f, 'h', stub_string, depth=3)
    expect_equal(f(1), 'called stub!called stub!')
})

h = function(x) 'called h'
t = function(x) h(x)
g = function(x) h(x)
r = function(x) paste0(t(x), g(x))
u = function(x) paste0(h(x), g(x))

f = function(x) paste0(h(x), r(x), u(x))

t_env = new.env(parent=baseenv())
assign('h', h, t_env)
environment(t) = t_env

u_env = new.env(parent=baseenv())
assign('g', g, u_env)
assign('h', h, u_env)
environment(u) = u_env

f_env = new.env(parent=baseenv())
assign('u', u, f_env)
assign('h', h, f_env)
assign('r', r, f_env)
environment(f) = f_env

a = function(x) x
environment(a) = f_env

test_that('mocked function is mocked at all depths across paths', {
    stub_string = 'called stub!'
    stub(f, 'h', stub_string, depth=4)
    expect_equal(f(1), 'called stub!called stub!called stub!called stub!called stub!')
})

.a = function(x) h(x)
test_that('mocks hidden functions', {
    stub_string = 'called stub!'
    stub(.a, 'h', stub_string, depth=4)
    expect_equal(f(1), 'called stub!called stub!called stub!called stub!called stub!')
})

test_that("Does not error if function contains double quoted assignment functions", {
    f <- function(x, nms) {
      base::names(x) <- base::tolower(nms)
      x
    }

    stub(f, "base::tolower", toupper)
    expect_equal(f(1, "b"), c(B = 1))

    stub(f, "base::names<-", function(x, value) stats::setNames(x, "d"))
    expect_equal(f(1, "b"), c(d = 1))
})
