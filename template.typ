#let term(long, short) = {
  [#long (short. #short)]
}

#let code(long, short) = {
  [#long (short. #raw(short))]
}