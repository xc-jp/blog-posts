---
layout: single
title: Composing C++20 Asio coroutines
issue-date: 2022.03.03
author: James Brock
tags: Boost Asio "coroutine functions" C++20 
excerpt: Explanation how to use Boost 1.78 Asio
---

C++20 coroutines are here, and the support for them in Boost 1.78 Asio is very good. 
They are, however, a bit tricky to use. 
In particular, I had to struggle for a few days to learn how to write Asio coroutine functions
which use Asio coroutines — in other words, how to compose Asio coroutines together.

Here are some Asio coroutine functions which call other Asio coroutine functions with a *nice API*.
When I say
*nice API*, I mean that you can use them to write code which correctly and asynchronously 
reads from a TCP socket stream, while writing in an imperative style of one-thing-after-another.

Reading from TCP this way has historically been hard, because when we read *N* bytes from TCP
then we’re not guaranteed to get *N* bytes, and if we got less than we expected, then
we have to loop back around and read from TCP again and wait for the result. If we understand
how this works then it’s not too hard to write code which does this correctly, but it’s a lot of
code and it doesn’t compose well and it’s hard to package it into a reusable library. 
We end up writing long chains of callbacks (continuations) and doing a lot of manual buffer
management. Asio with C++20 coroutines has dramatically improved this situation.

The trick is to keep one `boost::asio::streambuf` around for the entire lifetime
of each `boost::asio::ip::tcp::socket`, and always use that same `streambuf` to read
from the `socket`. Then we can read from the TCP stream in the imperative one-thing-after-another
style, which looks like this:

These are not *high-performance* functions, because they copy a lot of memory inefficiently. 
Asio and C++20 coroutines can be used to write *high-performance* functions in the same style.

So given a `socket` and a `streambuf` which have the same lifetime:

```c++
boost::asio::ip::tcp::socket socket;
boost::asio::streambuf streambuf;
```

This is the kind of imperative one-thing-after-another TCP-reading code that we want to write:

```c++
{
  // First read a `string` from the `socket` until we encounter a `char` `';'`.
  std::string s1 = co_await async_read_string_until(socket, streambuf, ';');

  // Next read a ASCII-encoded `uint32_t` from the `socket` until we encounter a `char` `';'`.
  uint32_t x1 = co_await async_read_uint_until(socket, streambuf, ';');

  // Next read a `std::vector<char>` of length *N* from the `socket`.
  std::vector<char> = co_await async_read_vector_n(socket, streambuf, 10);
}
```

This is how we can write those three functions `async_read_string_until`, `async_read_uint_until`, and `async_read_vector_n`:


```c++
/**
 * Asynchronously read a string until a delimiter character from a streambuf,
 * reading more from a tcp::socket if necessary. Consume the string.
 * Throw an exception if success is impossible.
 */
asio::awaitable<std::string>
async_read_string_until(tcp::socket &socket, asio::streambuf &b, char delim) {
  // “If the streambuf's get area already contains the delimiter, this
  // asynchronous operation completes immediately.” —
  // https://www.boost.org/doc/libs/1_78_0/doc/html/boost_asio/reference/async_read_until/overload5.html
  // The bytes_transferred will be the offset of the delimiter,
  // not the number of bytes read into the streambuf.
  auto [ec, bytes_transferred] = co_await asio::async_read_until(
      socket, b, delim, as_tuple(use_awaitable));
  if (ec) {
    throw std::runtime_error(string(__func__) + string(" / ") + ec.what());
  }
  asio::streambuf::const_buffers_type ibuf = b.data();
  std::string s(
      asio::buffers_begin(ibuf),
      asio::buffers_begin(ibuf) +
          (bytes_transferred - 1));
  b.consume(bytes_transferred);
  co_return s;
}

/**
 * Asynchronously read an ASCII uint32_t string until a delimeter character from
 * streambuf, reading more from a tcp::socket if necessary. Consume the string.
 * Throw an exception if success is impossible.
 */
asio::awaitable<uint32_t>
async_read_uint_until(tcp::socket &socket, asio::streambuf &b, char delim) {
  std::string s = co_await async_read_string_until(socket, b, delim);
  try {
    co_return boost::lexical_cast<uint32_t>(s);
  } catch (std::exception &ex) {
    throw std::runtime_error(string(__func__) + string(" / ") + ex.what());
  }
}

/**
 * Asynchronously read a data vector of length n bytes from a streambuf,
 * reading more from a tcp::socket if necessary. Consume the vector.
 * Throw an exception if success is impossible.
 */
asio::awaitable<std::vector<char>>
async_read_vector_n(tcp::socket &socket, asio::streambuf &b, size_t n) {
  // Do we have enough data already in the streambuf?
  // https://github.com/chriskohlhoff/asio/issues/621
  if (b.size() >= n) {
    std::vector<char> retbuf;
    asio::buffer_copy(asio::buffer(retbuf), b.data(), n);
    b.consume(n);
    co_return retbuf;
  }

  // Need more data in the streambuf.
  // “boost::asio::async_read: it does prepare and commit, you have to do
  // consume:” — https://dens.website/tutorials/cpp-asio/read-write-2
  auto [ec, bytes_transferred] = co_await asio::async_read(
      socket, b, asio::transfer_at_least(n - b.size()),
      as_tuple(use_awaitable));
  if (ec) {
    throw std::runtime_error(string(__func__) + string(" / ") + ec.what());
  }

  // Now there should be enough data in the streambuf.
  if (b.size() >= n) {
    std::vector<char> retbuf;
    asio::buffer_copy(asio::buffer(retbuf), b.data(), n);
    b.consume(n);
    co_return retbuf;
  }
  throw std::runtime_error(string(__func__) +
                           string(" / not enough data, wanted ") +
                           lexical_cast<string>(n) + string(" but got ") +
                           lexical_cast<string>(b.size()));
}
```

If you like this imperative one-thing-after-another style of asynchronous TCP socket reading but C++20 
is a bit too bleeding-edge for you to use at work, then I recommend the GHC Haskell compiler,
in which all network I/O is always asynchronous.

## Some further coroutine reading

https://www.boost.org/doc/libs/1_78_0/doc/html/boost_asio.html
https://dens.website/tutorials/cpp-asio/read-write
https://dens.website/tutorials/cpp-asio/read-write-2
https://dens.website/tutorials/cpp-asio/read-write-3
https://www.scs.stanford.edu/~dm/blog/c++-coroutines.html
http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2021/p2444r0.pdf
https://lastviking.eu/asio_composed.html
https://ericniebler.com/2020/11/08/structured-concurrency/
https://blog.panicsoftware.com/coroutines-introduction/
https://lewissbaker.github.io/

