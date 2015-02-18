import AppKit
typealias BaseObjCClass = NSObject

enum PureSwiftEnum {
  case Value, AnotherValue
}

protocol PureSwiftProtocol {
  var value: PureSwiftEnum { get }
  var size: CGSize { get }
}

class ObjCSubclass: BaseObjCClass, PureSwiftProtocol {
  var value: PureSwiftEnum = .Value
  var size: CGSize = CGSizeZero
}

class GenericClass<T where T: PureSwiftProtocol> {
  var node: T
  init(node: T) {
    self.node = node
  }

  func accessValue() -> PureSwiftEnum {
    return node.value
  }

  func accessSize() -> CGSize {
    return node.size
  }
}

class PureSwiftWrapper: PureSwiftProtocol {
  var objcInstance: ObjCSubclass

  init(objcInstance: ObjCSubclass) {
    self.objcInstance = objcInstance
  }

  var value: PureSwiftEnum {
    return objcInstance.value
  }

  var size: CGSize {
    return objcInstance.size
  }
}


let wrapper = PureSwiftWrapper(objcInstance: ObjCSubclass())
let objectGeneric = GenericClass(node: ObjCSubclass())
let wrapperGeneric = GenericClass(node: wrapper)

println(objectGeneric.accessValue())
println(wrapperGeneric.accessValue())
println(objectGeneric.accessSize())
println(wrapperGeneric.accessSize())
