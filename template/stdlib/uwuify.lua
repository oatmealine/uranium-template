local endings = {'rawr x3', 'OwO', 'UwU', 'o.O', '-.-', '>w<', '(˘ω˘)', 'σωσ', 'ʘwʘ', ':3', 'XD', 'nyaa~~', 'mya', '>_<', 'rawr', '^^', '^^;;', '(^•ω•^)'}

return function(str)
  str = string.lower(str)

  str = string.gsub(str, 'small', 'smol')
  str = string.gsub(str, 'cute', 'kawaii~')
  str = string.gsub(str, 'fluff', 'floof')
  str = string.gsub(str, 'love', 'luv')
  str = string.gsub(str, 'stupid', 'baka')
  str = string.gsub(str, 'meow', 'nya~')

  str = string.gsub(str, 'l', 'w')
  str = string.gsub(str, 'r', 'w')

  str = string.gsub(str, 'n([aeiou])', 'ny%1')

  str = string.gsub(str, '[.!?]%s', function(e) return e .. endings[math.random(1, #endings)] .. ' ' end)

  str = string.gsub(str, '(%s)(%a)(%a)', function(space, rep, other) if math.random() < 0.05 then return space .. rep .. '-' .. rep .. other else return space .. rep .. other end end)

  return str
end