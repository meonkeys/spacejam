fs = require('fs')
path = require 'path'
chai = require("chai")
expect = chai.expect
sinon = require("sinon")
sinonChai = require("sinon-chai")
chai.use(sinonChai)
isCoffee = require './isCoffee'
if isCoffee
  require '../../src/log'
  CLI = require '../../src/CLI'
  Spacejam = require '../../src/Spacejam'
  ChildProcess = require '../../src/ChildProcess'
else
  require '../../lib/log'
  CLI = require '../../lib/CLI'
  Spacejam = require '../../lib/Spacejam'
  ChildProcess = require '../../lib/ChildProcess'


describe "CLI", ->
  @timeout 30000

  processArgv = null

  cli = null
  spacejam = null
  exitStub = null
  testPackagesStub = null
  spawnSpy = null
  phantomjsScript = null

  before ->
    processArgv = process.argv

  after ->
    process.argv = processArgv

  beforeEach ->
    process.chdir(__dirname + "/../apps/leaderboard")
    delete process.env.PORT
    delete process.env.ROOT_URL
    delete process.env.MONGO_URL
    delete process.env.PACKAGE_DIRS

    process.argv = ['coffee', path.normalize __dirname + "/../bin/spacejam"]
    cli = new CLI()
    spacejam = cli.spacejam
    exitStub = sinon.stub(process, 'exit')
    testPackagesStub = sinon.stub(spacejam, 'testPackages')
    phantomjsScript = 'phantomjs-test-in-console.' + if isCoffee then 'coffee' else 'js'

  afterEach ->
    exitStub?.restore?()
    exitStub = null
    testPackagesStub?.restore?()
    testPackagesStub = null
    spawnSpy?.restore?()
    spawnSpy = null
    spacejam = null

  it "should call Spacejam.testPackages() with an empty options.packages array, if no packages where provided on the command line", ->
    process.argv.push "test-packages"
    cli.exec()
    expect(testPackagesStub).to.have.been.calledWith({packages: []})

  it "should call Spacejam.testPackages() with options.packages set to the packages provided on the command line", ->
    process.argv.push 'test-packages', '--settings', 'settings.json', 'package1', 'package2'
    cli.exec()
    expect(testPackagesStub).to.have.been.calledWith({settings: 'settings.json', packages: ['package1', 'package2']})

  it "should spawn phantomjs with the value of --phantomjs-options", (done)->
    log.setLevel 'debug'
    testPackagesStub.restore()
    spawnSpy = sinon.spy(ChildProcess, '_spawn')
    process.chdir(__dirname + "/../apps/leaderboard/packages/success")
    # We set mongo-url to mongodb:// so test will be faster
    process.argv.push 'test-packages', '--mongo-url', 'mongodb://', '--phantomjs-options=--ignore-ssl-errors=true --load-images=false', './'
    cli.exec()
    spacejam.on 'done', (code)=>
      try
        if code is 0 then done() else done("spacejam.done=#{code}")
        expect(spawnSpy).to.have.been.calledTwice
        expect(spawnSpy.secondCall.args[1]).to.deep.equal(['--ignore-ssl-errors=true', '--load-images=false', phantomjsScript])
      catch err
        done(err)
