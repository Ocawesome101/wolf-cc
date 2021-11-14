local lib = {}
function lib.insertIntoTable(t, n, i)
  local ogn = #t
  for j=ogn, n, -1 do
    t[j+1] = t[j]
  end
  t[n] = i
end
function lib.removeFromTable(t, n)
  local ogn = #t
  t[n] = nil
  for i=n+1, ogn, 1 do
    t[i-1] = t[i]
  end
  if n < ogn then t[#t] = nil end
end
return lib
