---
layout: post
title: "Password Generator in Swift"
description: "Password Generator in Swift"
category: Swift
tags: [swift, ios, apple, xcode]
---
{% include JB/setup %}

Simple password generator in Swift.

<!--more-->

One day I was chatting with other iOS devs and someone posted an example of password generator code. The code featured "for-i-in" loops and other things which didn't look much swifty to my eye.

I tried to find a real application for nice Swift features like generators, sequences and some functional methods like `reduce`. I went through a number of iterations to get to the final state. Here's the code I eventually came up with.

{% highlight swift %}
import Foundation

struct PasswordGenerator: SequenceType {
    let length: Int
    let characters: Set<Character>

    func generate() -> GeneratorOf<Character> {
        var currentLength: Int = 0
        return GeneratorOf<Character> {
            let randomIndex = Int(arc4random_uniform(UInt32(count(self.characters))))
            let setIndex = advance(self.characters.startIndex, randomIndex)
            return (currentLength++ < self.length ? self.characters[setIndex] : nil)
          }
    }

    func password() -> String {
        return reduce(self, "") { (pwd: String, char: Character) -> String in
            "".join([pwd, String(char)])
        }
    }
}

let characters = Set("АБВГДAAAAbCd1234567890-=!@#$%^&*()_+QWE˙ÎÓÔ◊ı´¨°•RTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?")

let passwordGenerator = PasswordGenerator(length: 10, characters: characters)

println(passwordGenerator.password())
println(passwordGenerator.password())
println(passwordGenerator.password())
println(passwordGenerator.password())

{% endhighlight %}

As you can see this code is using Swift 1.2 features, such as new `Set` data type.

The general idea is to create a password generator for a given set of characters to generate passwords of the given length. I'm not claiming here that this is the best design ever. Probably it would be better to have a function that takes a set of characters and password length as an input and then do all heavy lifting in that function.

However, let's walk through this code.

The `PasswordGenerator` is a sequence since it conforms to `SequenceType` protocol. As part of protocol implementation this struct needs to implement `generate()` function that returns another Swift type `Generator`. In this example I'm generating characters for a password, so I chose to initialize password generator with a set of characters (`characters`) and length of the password to be generated (`length`).

Note that I'm not using any unicode specific code at all. That's the beauty of `String` type in Swift. Since `String` conforms to the very same `SequenceType` it can easily be converted to an array or a set, and what's even better, it will be an array or a set of **unicode** characters.

OK, so back to `PasswordGenerator`. `generate()` function returns generator of `Character` where `GeneratorOf` is another Swift generic type useful to declare generators of a certain type. Inside the function I'm creating a generator of `Character` with a closure, this closure captures `currentLength` variable as well as `self`. The closure first generates a random index of an element in the set using good old `arc4random_uniform`. The `randomIndex` is of type `Int` and can not be used as a set index. The set index in this case needs to be of type `SetIndex<Character>`. To get set index I'm using standard library function `advance` that  gives me a `randomIndex` set index equivalent for a set. Finally I can get a character from the set, incrementing `currentLength` and comparing it to `self.length` along the lines to know when to stop. Note the use of `self`, this is required because it's a closure.

Last step is to implement `password()` function that actually generates passwords. This is where I can use the fact that `PasswordGenerator` is a sequence. Thanks to that I am able to use standard library `reduce` on `self`. Reduce iterates through the sequence on each step getting a random element from the characters set it then appends new character to accumulator string using `join` function.

Without a single for-i-in loop I get a simple password generator that demoes beauty and flexibility of Swift and is yet open for further improvements.
