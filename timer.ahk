/*
  Usage:

  t := new timer()
  Sleep, 3000
  Msgbox % t.toMSMs()

*/

class timer
{
  __New()
  {
    DllCall("QueryPerformanceCounter", "Int64 *", s)
    DllCall("QueryPerformanceFrequency", "Int64 *", f)
    this.frequency := 1000 / f
    this.start := s
    this.paused := 0
  }

  pause()
  {
    DllCall("QueryPerformanceCounter", "Int64 *", t)
    if this.paused
    {
      this.start += t - this.paused
      this.paused := 0
    }
    else
    {
      this.paused := t
    }
  }

  reset() ;resets timer to 0
  {
    DllCall("QueryPerformanceCounter", "Int64 *", s)
    this.start := s
    if this.paused
      this.paused := s
  }

  check() ;returns time elapsed in ms
  {
    DllCall("QueryPerformanceCounter", "Int64 *", e)
    return ((this.paused ? this.paused : e) - this.start) * this.frequency
  }

  ;The following functions print human readable time strings, eg: toMSMs() would return something like "12:33:841"
  toHMSMs()
  {
    return this.timestamp()
  }

  toHMS()
  {
    return this.timestamp("%02\h:%02\m:%02\s")
  }

  toMSMs()
  {
    return this.timestamp("%02\m:%02\s:%03\ms")
  }

  toMS()
  {
    return this.timestamp("%02\m:%02\s")
  }
  
  ;Works sort of like printf with added escape sequences
  ;\h = current hours on timer
  ;\m = current minutes on timer
  ;\s = current seconds on timer
  ;\ms = current ms on timer
  ;\raw = total ms on timer
  ;Example:
  ;%02\h:%02\m:%02\s:%03\ms -> 01:36:12:000
  ;%<optional 0><length><escape sequence>  ;Optional 0 pads with zeroes if the number is less than length
  timestamp(format="%02\h:%02\m:%02\s:%03\ms")
  {
    static buf
    if (buf = "")
      VarSetCapacity(buf, 512)
    params := [], raw := floor(this.check()), h := raw // 3600000, m := mod(raw // 60000, 60), s := mod(raw // 1000, 60), ms := mod(raw, 1000)
    while(RegexMatch(format, "S)\\(h|ms|s|m|raw)", match))
    {
      params.Insert("int"), params.Insert(%match1%)
      StringReplace, format, format, % "\" match1, i
    }
    DllCall("wsprintf", "str", buf, "str", format, params*)
    return buf
  }
}
