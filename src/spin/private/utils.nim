proc newUnmanagedStr*(str: string): cstring =
  result = cstring(createU(char, str.len + 1))
  copyMem(result, unsafeAddr str[0], str.len + 1)
