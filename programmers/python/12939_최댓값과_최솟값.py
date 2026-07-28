def solution(s):
    arr = s.split(' ')
    nums = list(map(int, arr))
    
    minN = min(nums)
    maxN = max(nums)
    return f"{minN} {maxN}"
