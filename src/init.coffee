path = require 'path'

yargs = require 'yargs'

Command = require './command'
fs = require './fs'

module.exports =
class Init extends Command
  @commandNames: ['init']

  supportedSyntaxes: ['coffeescript', 'javascript']

  parseOptions: (argv) ->
    options = yargs(argv).wrap(100)

    options.usage """
      Usage:
        recrue init -p <package-name>
        recrue init -p <package-name> --syntax <javascript-or-coffeescript>
        recrue init -p <package-name> --template /path/to/your/package/template

        recrue init -t <theme-name>
        recrue init -t <theme-name> -c ~/Downloads/Dawn.tmTheme
        recrue init -t <theme-name> --template /path/to/your/theme/template

      Generates code scaffolding for either a theme or package depending
      on the option selected.
    """
    options.alias('p', 'package').string('package').describe('package', 'Generates a basic package')
    options.alias('s', 'syntax').string('syntax').describe('syntax', 'Sets package syntax to CoffeeScript or JavaScript')
    options.alias('t', 'theme').string('theme').describe('theme', 'Generates a basic theme')
    options.alias('h', 'help').describe('help', 'Print this usage message')
    options.string('template').describe('template', 'Path to the package or theme template')

  run: (options) ->
    {callback} = options
    options = @parseOptions(options.commandArgs)
    if options.argv.package?.length > 0
      packagePath = path.resolve(options.argv.package)
      syntax = options.argv.syntax or @supportedSyntaxes[0]
      if syntax not in @supportedSyntaxes
        return callback("You must specify one of #{@supportedSyntaxes.join(', ')} after the --syntax argument")
      templatePath = @getTemplatePath(options.argv, "package-#{syntax}")
      @generateFromTemplate(packagePath, templatePath)
      callback()
    else if options.argv.theme?.length > 0
      themePath = path.resolve(options.argv.theme)
      templatePath = @getTemplatePath(options.argv, 'theme')
      @generateFromTemplate(themePath, templatePath)
      callback()
    else if options.argv.package?
      callback('You must specify a path after the --package argument')
    else if options.argv.theme?
      callback('You must specify a path after the --theme argument')
    else
      callback('You must specify either --package, --theme to `recrue init`')

  generateFromTemplate: (packagePath, templatePath, packageName) ->
    packageName ?= path.basename(packagePath)
    packageAuthor = process.env.GITHUB_USER or 'soldat'

    fs.makeTreeSync(packagePath)

    for childPath in fs.listRecursive(templatePath)
      templateChildPath = path.resolve(templatePath, childPath)
      relativePath = templateChildPath.replace(templatePath, "")
      relativePath = relativePath.replace(/^\//, '')
      relativePath = relativePath.replace(/\.template$/, '')
      relativePath = @replacePackageNamePlaceholders(relativePath, packageName)

      sourcePath = path.join(packagePath, relativePath)
      continue if fs.existsSync(sourcePath)
      if fs.isDirectorySync(templateChildPath)
        fs.makeTreeSync(sourcePath)
      else if fs.isFileSync(templateChildPath)
        fs.makeTreeSync(path.dirname(sourcePath))
        contents = fs.readFileSync(templateChildPath).toString()
        contents = @replacePackageNamePlaceholders(contents, packageName)
        contents = @replacePackageAuthorPlaceholders(contents, packageAuthor)
        contents = @replaceCurrentYearPlaceholders(contents)
        fs.writeFileSync(sourcePath, contents)

  replacePackageAuthorPlaceholders: (string, packageAuthor) ->
    string.replace(/__package-author__/g, packageAuthor)

  replacePackageNamePlaceholders: (string, packageName) ->
    placeholderRegex = /__(?:(package-name)|([pP]ackageName)|(package_name))__/g
    string = string.replace placeholderRegex, (match, dash, camel, underscore) =>
      if dash
        @dasherize(packageName)
      else if camel
        if /[a-z]/.test(camel[0])
          packageName = packageName[0].toLowerCase() + packageName[1...]
        else if /[A-Z]/.test(camel[0])
          packageName = packageName[0].toUpperCase() + packageName[1...]
        @camelize(packageName)

      else if underscore
        @underscore(packageName)

  replaceCurrentYearPlaceholders: (string) ->
    string.replace '__current_year__', new Date().getFullYear()

  getTemplatePath: (argv, templateType) ->
    if argv.template?
      path.resolve(argv.template)
    else
      path.resolve(__dirname, '..', 'templates', templateType)

  dasherize: (string) ->
    string = string[0].toLowerCase() + string[1..]
    string.replace /([A-Z])|(_)/g, (m, letter, underscore) ->
      if letter
        "-" + letter.toLowerCase()
      else
        "-"

  camelize: (string) ->
    string.replace /[_-]+(\w)/g, (m) -> m[1].toUpperCase()

  underscore: (string) ->
    string = string[0].toLowerCase() + string[1..]
    string.replace /([A-Z])|(-)/g, (m, letter, dash) ->
      if letter
        "_" + letter.toLowerCase()
      else
        "_"
