def solution(s):
    nums = [int(x) for x in s.split()]
    return f"{min(nums)} {max(nums)}"
    
