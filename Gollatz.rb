#! /usr/bin/env ruby
## -*- mode: ruby; coding: utf-8 -*-
## = generalized Collatz prediction
## Author:: Itsuki Noda
## Version:: 0.0 2024/03/12 I.Noda
##
## === History
## * [2024/03/12]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

def $LOAD_PATH.addIfNeed(path, lastP = false)
  existP = self.index{|item| File.identical?(File.expand_path(path),
                                             File.expand_path(item))} ;
  if(!existP) then
    if(lastP) then
      self.push(path) ;
    else
      self.unshift(path) ;
    end
  end
end

$LOAD_PATH.addIfNeed("~/lib/ruby");
# $LOAD_PATH.addIfNeed(File.dirname(__FILE__));

require 'pp' ;

require 'WithConfParam.rb' ;

#--======================================================================
#++
## Generalized Collatz
class Gollatz < WithConfParam
  #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #++
  ## default values for WithConfParam#getConf(_key_).
  DefaultConf = {
    base: 2,
    mode: :normal,  # or :minus, :one
  } ;
  ## the list of attributes that are initialized by getConf().
  DirectConfAttrList = [:base, :mode] ;
  
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #++
  ## base number
  attr :base, true ;
  ## mode
  attr :mode, true ;

  #--------------------------------------------------------------
  #++
  ## description of method initialize
  ## _baz_:: about argument baz.
  def initialize(_conf = {})
    super(_conf) ;
  end

  #--------------------------------------------------------------
  #++
  ## one cycle calc.
  ## _n_:: current number
  ## *return*:: next number
  def cycle(_n)
    if(_n % @base == 0) then
      return _n / @base ;
    else
      case(@mode)
      when :normal ;
        return (@base + 1) * _n + (@base - _n % @base) ;
      when :minus ;
        return (@base + 1) * _n - (_n % @base) ;
#      when :one ;   # すぐ無限ループになる。
#        return (@base + 1) * _n + 1 ;
      else
        raise "unknown mode: " + @mode ;
      end
    end
  end
  

  #--------------------------------------------------------------
  #++
  ## description of method foo
  ## _bar_:: about argument bar
  ## *return*:: about return value
  def each(_startN, _loopM = nil, &_block) # :yield: _n, _k
    _n = _startN ;
    _k = 0 ;
    while(_loopM.nil? || _k < _loopM)
      _n = cycle(_n) ;
      _k += 1 ;
      _block.call(_n, _k) ;
    end
  end

  #--------------------------------------------------------------
  #++
  ## trail until 1
  ## _startN_:: about argument bar
  ## *return*:: list to 1.
  def trailUntilOne(_startN, _destN = 1)
    _trail = [_startN] ;
    self.each(_startN){|_n,_k|
      _trail.push(_n) ;
      break if(_n == _destN && _k > 0) ;
#      p _trail ;
    }
    return _trail ;
  end

  #--------------------------------------------------------------
  #++
  ## trail until loop
  ## _startN_:: about argument bar
  ## *return*:: list to 1.
  def trailUntilLoop(_startN, _destList = [])
    _trail = _destList.dup ;
    _trail.push(_startN) ;
    self.each(_startN){|_n,_k|
      _loopP = _trail.include?(_n) ;
      _trail.push(_n) ;
      break if(_loopP) ;
    }
    return _trail ;
  end

  #--------------------------------------------------------------
  #++
  ## get pick trail
  ## _startN_:: about argument bar
  ## *return*:: min of trail
  def getTrailInfo(_startN)
    _trail = trailUntilLoop(_startN) ;
    _headIndex = _trail.find_index(_trail.last) ;
    _loopTrail = _trail[_headIndex..-2] ;

    _approachEnd = nil ;
    _trail.each_index{|_idx|
      if(_loopTrail.include?(_trail[_idx])) then
        _approachEnd = _idx ;
        break ;
      end
    }
    _approachTrail = _trail[0..._approachEnd] ;
    
    _trailInfo = {
      start: _startN,
      loopBottom: _loopTrail.min(),
      loopSize: _loopTrail.size,
      trail: _trail,
      approachTrail: _approachTrail,
      loopTrail: _loopTrail,
    } ;

    return _trailInfo ;
  end
  
  #--------------------------------------------------------------
  #++
  ## pick loop trail
  ## _startN_:: about argument bar
  ## *return*:: min of trail
  def loopTrail(_startN)
    return getTrailInfo(_startN)[:loopTrail] ;
  end

  #--------------------------------------------------------------
  #++
  ## find bottom of loop trail until loop
  ## _startN_:: about argument bar
  ## *return*:: min of trail
  def bottomOfLoopTrail(_startN)
    _trailInfo = getTrailInfo(_startN) ;
    return [_trailInfo[:loopBottom], _trailInfo[:loopSize]] ;
  end

  #--------------------------------------------------------------
  #++
  ## bottom table
  ## _untilN_:: 
  ## *return*:: table of bottom and its member in
  ##     { bottom => { bottom: _bottom_, period: _period_, members: [...] } }
  def bottomTable(_untilN)
    _bottomTable = {} ;
    (1.._untilN).each{|_n|
      (_bottom, _loopSize) = bottomOfLoopTrail(_n) ;
      _bottomTable[_bottom] = { bottom: _bottom,
                                loopSize: _loopSize,
                                members: [] } if(_bottomTable[_bottom].nil?) ;
      _bottomTable[_bottom][:members].push(_n) ;
    }
    return _bottomTable ;
  end

  #--------------------------------------------------------------
  #++
  ## loop trail table
  ## _untilN_:: 
  ## *return*:: table of loop trail infomation
  ##     { bottom => LoopTrailInfo }
  ##     LoopTrailInfo ::= { bottom: _bottom_,
  ##                         loopSize: _loopSize_,
  ##                         lower: _lowerMember_,
  ##                         loop: [...],
  ##                         members: [...] }
  def getTrailLoopTable(_untilN, _shortP = false)
    @trailLoopTable = {} ;
    (1.._untilN).each{|_startN|
      _trailInfo = getTrailInfo(_startN) ;
#      p _trailInfo ;
      _bottom = _trailInfo[:loopBottom]
      if(@trailLoopTable[_bottom].nil?) then
        _loopTrail = _trailInfo[:loopTrail] ;
        _normalizedTrail = (_loopTrail[_loopTrail.find_index(_bottom)..-1] +
                            _loopTrail[0..._loopTrail.find_index(_bottom)]) ;
        @trailLoopTable[_bottom] = {
          loopBottom: _bottom,
          loopSize: _trailInfo[:loopSize],
          members: [],
          loopTrail: _normalizedTrail,
        } ;
      end
      @trailLoopTable[_bottom][:members].push(_startN) ;
      @trailLoopTable[_bottom][:memberSize] =
        @trailLoopTable[_bottom][:members].size ;
    }
    if(_shortP) then
      @trailLoopTable.each{|_base, _trailInfo|
        _trailInfo[:minMember] = _trailInfo[:members].first ;
        _trailInfo[:maxMember] = _trailInfo[:members].last ;
        [:members, :loopTrail].each{|_key|
          _trailInfo.delete(_key) ;
        }
      }
    end
    
    return @trailLoopTable ;
  end

  #--////////////////////////////////////////////////////////////
  #--============================================================
  #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #--------------------------------------------------------------
end # class Gollatz

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'test/unit'

  #--============================================================
  #++
  # :nodoc:
  ## unit test for this file.
  class TC_Foo < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData = nil ;

    #----------------------------------------------------
    #++
    ## show separator and title of the test.
    def setup
#      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## about test_a
    def test_a
      _gol = Gollatz.new({base: 101}) ;
      _gol.each(1, 1000) {|_n, _k|
        p [_k, _n] ;
      }
    end

    #----------------------------------------------------
    #++
    ## about test_b
    def test_b
      (2..100).each{|_base|
        _gol = Gollatz.new({base: _base}) ;
#        _trail = _gol.trailUntilOne(_base + 1) ;
#        _trail = _gol.trailUntilOne(5) ;
        _trail = _gol.trailUntilOne(1) ;
        p [_base, _trail.size] ;
      }
    end

    #----------------------------------------------------
    #++
    ## loop
    def test_c
      (2..10).each{|_base|
        _gol = Gollatz.new({base: _base}) ;
        _trail = _gol.trailUntilLoop(5) ;
        p [_base, _trail] ;
      }
    end

    #----------------------------------------------------
    #++
    ## bottom list
    def test_d
      (2..1000).each{|_base|
#        _gol = Gollatz.new({base: _base, mode: :minus}) ;
#        _gol = Gollatz.new({base: _base, mode: :one}) ;
        _gol = Gollatz.new({base: _base, mode: :normal}) ;        

        _bottomTable = _gol.bottomTable(10000) ;
        p [_base,
           _bottomTable.map{|_b, _entry|
             [_entry[:bottom], _entry[:loopSize], _entry[:members].size] },
          ]
      }
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
