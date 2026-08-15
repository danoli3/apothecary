#pragma once
// gcc-10 libstdc++ has <bit> but not std::bit_cast (GCC 11 / C++20).
#include <bit>
#if !defined(__cpp_lib_bit_cast) || (__cpp_lib_bit_cast < 201806L)
#include <cstring>
#include <type_traits>
namespace std {
template <class To, class From>
inline To bit_cast(const From& src) noexcept {
    static_assert(sizeof(To) == sizeof(From), "bit_cast size mismatch");
    static_assert(is_trivially_copyable<To>::value, "To must be trivially copyable");
    static_assert(is_trivially_copyable<From>::value, "From must be trivially copyable");
    To dst;
    memcpy(&dst, &src, sizeof(To));
    return dst;
}
} // namespace std
#endif
