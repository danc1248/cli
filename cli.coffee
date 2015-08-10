# reads command line input for coffee scripts

# USAGE:
# coffee cli.coffee --a="1,2,3" -b false --n="100" --o "{\"hello\":\"world\"}" -s simple
# p = new Parser(a: Array, b: Boolean, n: Number, o: Object, s: String)
# p.getOptions()
# {
#   a: [ 1, 2, 3 ],
#   b: false,
#   n: 100,
#   o: { hello: 'world' },
#   s: 'simple'
# }

class Parser
  # I dont expect anyone to actually pass in args, just let it use argv by default
  constructor: (format = null, args = null)->
    if args is null
      args = JSON.parse(JSON.stringify(process.argv)).reverse()

      # the element is the command coffee
      args.pop()

      # the second element is the script name
      args.pop()

    else
      args = JSON.parse(JSON.stringify(args)).reverse()

    if format is null
      @format = null
      @requried = null
    else
      @format = {}
      @required = {}
      for key, value of format
        if typeof value is "object" and value.length is 1
          @required[key] = false
          @format[key] = value[0]
        else
          @required[key] = true
          @format[key] = value

    @args = args
    @options = {}

    @_parse()

  getOptions: ->
    return @options

  @execute: (format)->
    parser = new @(format)
    return parser.getOptions()

  # pop the next value of the array and return it
  # does nothing if the next value is an option
  _getNextValue: ->
    if @args.length is 0
      return null
    else
      elem = @args.pop()

      if elem[0] is "-"
        @args.push elem
        return null

      else
        return elem

  # add an option to the class
  _addOption: (key, value)->
    if value is null
      console.error "ERROR: unexpected null value for: #{key}"
    else if @options[key] isnt undefined
      console.error "ERROR: option already set for: #{key} - #{@options[key]} - #{value}"
    else
      @options[key] = @_formatValue(key, value)
    return

  # if the user defined a format, convert the value:
  # @param key used to look up the user format
  # @param value STRING we assume all input is a string because its from the cli, in fact we coerce it to be so
  # @return formatted value
  _formatValue: (key, value)->
    # no defined format? thats cool, just assume everything is good
    if @format is null
      return value

    else if @format[key] is undefined
      console.error "ERROR: no format for: #{key}"
      return value

    else
      type = @format[key]
      value = "#{value}"

      switch type
        when Boolean
          return (value is "true" or value is "1")

        when Number
          return +value

        when String
          return "#{value}"

        when Array
          return "#{value}".split(",").map (elem)->
            # if its an array of Numbers, we'll format those also
            # I suppose you could do the same thing for booleans if you wanted to
            if elem is "#{+elem}"
              return +elem
            else
              return elem

        when Object
          try
            json = JSON.parse(value)
          catch e
            console.error "ERROR: failed to json parse: #{value}"
            json = {}

          return json

        else
          console.error "ERROR: unknown format: #{type}"
          return null
  # end _formatValue


  # parse the argv
  _parse: ->
    # construct the options from the @args
    while elem = @args.pop()

      # look for "-a"
      match = /^-(\S)$/.exec elem
      if match isnt null
        option = match[1]

        # is it of the format: "-a value"
        val = @_getNextValue()
        if val is null
          @_addOption(option, true)
        else
          @_addOption(option, val)

        continue

      # look for --option=value
      # note the non-greedy first match: --hhh="what=the=heck"
      # note this match needs to be checked before the next one!
      match = /^--(\S+?)=(.+)$/.exec elem
      if match isnt null
        option = match[1]
        val = match[2]

        @_addOption(option, val)
        continue

      # look for "--option"
      match = /^--(\S+)$/.exec elem
      if match isnt null
        option = match[1]

        # look for "--option value"
        val = @_getNextValue()
        if val is null
          @_addOption(option, true)
        else
          @_addOption(option, val)

        continue

      console.error "ERROR: what a weird format! #{elem}"

    # verify that all required options exist using @format
    if @format isnt null
      for key, type of @format
        # if its [Number] it means its optional
        if @required[key] and @options[key] is undefined
          console.error "ERROR: missing required paramter: #{key}"

    return
  # end _parse

# test:
# p = new Parser(a: Array, b: Boolean, n: Number, o: Object, s: [String])
# console.log p.getOptions()

module.exports = Parser