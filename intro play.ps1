# this is a comment (duh!)

#############################################
# parens do precidence control (like normal)
5 * (1+2)
#-> 15
(dir).Count
#-> 42

#############################################
# subexpression parse $()
"The answer is (2+2)"
#-> "The answer is (2+2)"
"The answer is $(2+2)"
#-> "The answer is 4"

# they're pretty powerful!
$value = 10
$result = $(
    if($value -gt 0)
        { $true }
    else { $false })
$result
#-> True

#############################################
# list eval is coolish: @()
"Hello".Length
#-> 5
@("Hello").Length
#-> 1
(Get-ChildItem).Count
#-> 12
(Get-ChildItem *.txt).Count
@(Get-ChildItem *.txt).Count
#-> 1

