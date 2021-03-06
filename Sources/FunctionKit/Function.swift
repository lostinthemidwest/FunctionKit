//
//  Function.swift
//  FunctionKit
//
//  Created by Michael Pangburn on 4/9/18.
//

/// An internal helper function to promote a Swift function of type `(Input) -> Output` to a `Function<Input, Output>`.
/// This is declared as a free function avoid the need to specify the `Function` input and output types
/// when promoting a Swift function of different input/output types inside the `Function` class.
internal func promote<Input, Output>(_ f: @escaping (Input) -> Output) -> Function<Input, Output> {
    return Function(f)
}

/// A wrapper around a Swift function designed to provide powerful functional operations
/// such as composition and currying.
public final class Function<Input, Output> {
    /// The wrapped Swift function.
    /// This function is invoked with `apply(_:)`.
    private let _apply: (Input) -> Output

    /// Calls the function with the given input.
    ///
    /// ```
    /// let fooHasPrefix: (String) -> Bool = "foo".hasPrefix
    /// fooHasPrefix("fo")                 // true
    /// Function(fooHasPrefix).apply("fo") // true
    /// ```
    /// - Parameter input: The input with which to call the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply(_ input: Input) -> Output {
        return _apply(input)
    }

    /// Creates a `Function` from a Swift function.
    ///
    /// By promoting a Swift function to a `Function`, it gains access to powerful functional operations
    /// such as composition and currying.
    /// - Parameter f: The Swift function to promote.
    /// - Returns: The promoted function.
    public init(_ f: @escaping (Input) -> Output) {
        self._apply = f
    }
}

// MARK: - Common Functions

extension Function {
    /// The identity function, i.e. a function that returns its input unchanged.
    /// - Returns: A function that returns its input unchanged.
    public static func identity<A>() -> Function<A, A> {
        return .init { $0 }
    }

    /// Returns a function whose output is constant, regardless of its input.
    /// - Parameter value: The value to return regardless of the input of the produced function.
    /// - Returns: A function that produces the same output regardless of its input.
    public static func constant<Value, Ignored>(_ value: Value) -> Function<Ignored, Value> {
        return .init { _ in value }
    }
}

// MARK: - Key Path Compatibility

extension Function {
    /// Returns a getter function for the given key path.
    /// - Parameter keyPath: The key path for which to produce the getter function.
    /// - Returns: A getter function for the given key path.
    public static func get(_ keyPath: KeyPath<Input, Output>) -> Function<Input, Output> {
        return .init { input in
            input[keyPath: keyPath]
        }
    }

    /// Returns a setter function for the given key path.
    /// - Parameter keyPath: The key path for which to produce the setter function.
    /// - Returns: A setter function for the given key path.
    /// - Warning: Using this function with mutable reference types may yield unexpected results.
    public static func update(_ keyPath: WritableKeyPath<Output, Input>) -> Function<Function<Input, Input>, Function<Output, Output>> {
        return .init { update in
            .init { root in
                var copy = root
                copy[keyPath: keyPath] = update.apply(root[keyPath: keyPath])
                return copy
            }
        }
    }
}

// MARK: - Forward Composition

extension Function {
    /// Returns a new function that pipes the output of this function into another function.
    ///
    /// This operation is known as forward function composition.
    /// - Parameter other: The function into which to pipe the output of this function.
    /// - Returns: A new function that pipes the output of this function into the given function.
    public func piped<C>(into other: Function<Output, C>) -> Function<Input, C> {
        return piped(into: other.apply)
    }

    /// Returns a new function that pipes the output of this function into another function.
    ///
    /// This operation is known as forward function composition.
    /// - Parameter other: The function into which to pipe the output of this function.
    /// - Returns: A new function that pipes the output of this function into the given function.
    public func piped<C>(into other: @escaping (Output) -> C) -> Function<Input, C> {
        return .init { input in
            other(self.apply(input))
        }
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B>(
        _ f: Function<Input, B>,
        _ g: Function<B, Output>
    ) -> Function<Input, Output> {
        return f.piped(into: g)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B>(
        _ f: @escaping (Input) -> B,
        _ g: @escaping (B) -> Output
    ) -> Function<Input, Output> {
        return promote(f).piped(into: g)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C>(
        _ f: Function<Input, B>,
        _ g: Function<B, C>,
        _ h: Function<C, Output>
    ) -> Function<Input, Output> {
        return f.piped(into: g).piped(into: h)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C>(
        _ f: @escaping (Input) -> B,
        _ g: @escaping (B) -> C,
        _ h: @escaping (C) -> Output
    ) -> Function<Input, Output> {
        return promote(f).piped(into: g).piped(into: h)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D>(
        _ f: Function<Input, B>,
        _ g: Function<B, C>,
        _ h: Function<C, D>,
        _ i: Function<D, Output>
    ) -> Function<Input, Output> {
        return f.piped(into: g).piped(into: h).piped(into: i)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D>(
        _ f: @escaping (Input) -> B,
        _ g: @escaping (B) -> C,
        _ h: @escaping (C) -> D,
        _ i: @escaping (D) -> Output
    ) -> Function<Input, Output> {
        return promote(f).piped(into: g).piped(into: h).piped(into: i)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D, E>(
        _ f: Function<Input, B>,
        _ g: Function<B, C>,
        _ h: Function<C, D>,
        _ i: Function<D, E>,
        _ j: Function<E, Output>
    ) -> Function<Input, Output> {
        return f.piped(into: g).piped(into: h).piped(into: i).piped(into: j)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D, E>(
        _ f: @escaping (Input) -> B,
        _ g: @escaping (B) -> C,
        _ h: @escaping (C) -> D,
        _ i: @escaping (D) -> E,
        _ j: @escaping (E) -> Output
    ) -> Function<Input, Output> {
        return promote(f).piped(into: g).piped(into: h).piped(into: i).piped(into: j)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D, E, F>(
        _ f: Function<Input, B>,
        _ g: Function<B, C>,
        _ h: Function<C, D>,
        _ i: Function<D, E>,
        _ j: Function<E, F>,
        _ k: Function<F, Output>
    ) -> Function<Input, Output> {
        return f.piped(into: g).piped(into: h).piped(into: i).piped(into: j).piped(into: k)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next.
    ///
    /// This operation is known as forward function composition.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function.
    public static func pipeline<B, C, D, E, F>(
        _ f: @escaping (Input) -> B,
        _ g: @escaping (B) -> C,
        _ h: @escaping (C) -> D,
        _ i: @escaping (D) -> E,
        _ j: @escaping (E) -> F,
        _ k: @escaping (F) -> Output
    ) -> Function<Input, Output> {
        return promote(f).piped(into: g).piped(into: h).piped(into: i).piped(into: j).piped(into: k)
    }
}

// MARK: - Concatenation

extension Function where Input == Output {
    /// Returns a new function that pipes the output of this function into the other.
    ///
    /// Concatenation is forward composition restricted to functions whose input and output types are the same.
    /// - Parameter other: The function with which to concatenate.
    /// - Returns: A new function concatenating this function with the other.
    public func concatenated(with other: Function<Input, Output>) -> Function<Input, Output> {
        return .concatenation(self, other)
    }

    /// Returns a new function that pipes the output of this function into the other.
    ///
    /// Concatenation is forward composition restricted to functions whose input and output types are the same.
    /// - Parameter other: The function with which to concatenate.
    /// - Returns: A new function concatenating this function with the other.
    public func concatenated(with other: @escaping (Input) -> Output) -> Function<Input, Output> {
        return .concatenation(apply, other)
    }

    /// Returns a function that pipes the output of each function into the next, and so forth for all given functions.
    ///
    /// Concatenation is forward composition restricted to functions whose input and output types are the same.
    /// - Parameter functions: The functions to concatenate in sequence.
    /// - Parameter finally: An optional function as a convenience for trailing closure syntax.
    /// - Returns: A function concatenating the given functions.
    public static func concatenation(
        _ functions: Function<Input, Output>...,
        and finally: @escaping (Input) -> Output = { $0 }
    ) -> Function<Input, Output> {
        return .concatenation(functions.map { $0.apply }, and: finally)
    }

    /// Returns a function that pipes the output of each function into the next, and so forth for all given functions.
    ///
    /// Concatenation is forward composition restricted to functions whose input and output types are the same.
    /// - Parameter functions: The functions to concatenate in sequence.
    /// - Parameter finally: An optional function as a convenience for trailing closure syntax.
    /// - Returns: A function concatenating the given functions.
    public static func concatenation(
        _ functions: (Input) -> Output...,
        and finally: @escaping (Input) -> Output = { $0 }
    ) -> Function<Input, Output> {
        return .concatenation(functions, and: finally)
    }

    internal static func concatenation(
        _ functions: [(Input) -> Output],
        and finally: @escaping (Input) -> Output
    ) -> Function<Input, Output> {
        return .init { input in
            finally(functions.reduce(input) { input, f in f(input) })
        }
    }
}

// MARK: - Optional Chaining

extension Function {
    /// Returns a new function that pipes the output of this function into the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Parameter other: The function with which to chain.
    /// - Returns: A new function that pipes the output of this function into the next when not `nil`.
    public func chained<B, C>(with other: Function<B, C?>) -> Function<Input, C?> where Output == B? {
        return chained(with: other.apply)
    }

    /// Returns a new function that pipes the output of this function into the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Parameter other: The function with which to chain.
    /// - Returns: A new function that pipes the output of this function into the next when not `nil`.
    public func chained<B, C>(with other: @escaping (B) -> C?) -> Function<Input, C?> where Output == B? {
        return .init { input in
            self.apply(input).flatMap(other)
        }
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C>(
        _ f: Function<Input, B?>,
        _ g: Function<B, C?>
    ) -> Function<Input, Output> where Output == C? {
        return f.chained(with: g)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C>(
        _ f: @escaping (Input) -> B?,
        _ g: @escaping (B) -> C?
    ) -> Function<Input, Output> where Output == C? {
        return promote(f).chained(with: g)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D>(
        _ f: Function<Input, B?>,
        _ g: Function<B, C?>,
        _ h: Function<C, D?>
    ) -> Function<Input, Output> where Output == D? {
        return f.chained(with: g).chained(with: h)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D>(
        _ f: @escaping (Input) -> B?,
        _ g: @escaping (B) -> C?,
        _ h: @escaping (C) -> D?
    ) -> Function<Input, Output> where Output == D? {
        return promote(f).chained(with: g).chained(with: h)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E>(
        _ f: Function<Input, B?>,
        _ g: Function<B, C?>,
        _ h: Function<C, D?>,
        _ i: Function<D, E?>
    ) -> Function<Input, Output> where Output == E? {
        return f.chained(with: g).chained(with: h).chained(with: i)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E>(
        _ f: @escaping (Input) -> B?,
        _ g: @escaping (B) -> C?,
        _ h: @escaping (C) -> D?,
        _ i: @escaping (D) -> E?
    ) -> Function<Input, Output> where Output == E? {
        return promote(f).chained(with: g).chained(with: h).chained(with: i)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E, F>(
        _ f: Function<Input, B?>,
        _ g: Function<B, C?>,
        _ h: Function<C, D?>,
        _ i: Function<D, E?>,
        _ j: Function<E, F?>
    ) -> Function<Input, Output> where Output == F? {
        return f.chained(with: g).chained(with: h).chained(with: i).chained(with: j)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E, F>(
        _ f: @escaping (Input) -> B?,
        _ g: @escaping (B) -> C?,
        _ h: @escaping (C) -> D?,
        _ i: @escaping (D) -> E?,
        _ j: @escaping (E) -> F?
    ) -> Function<Input, Output> where Output == F? {
        return promote(f).chained(with: g).chained(with: h).chained(with: i).chained(with: j)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E, F, G>(
        _ f: Function<Input, B?>,
        _ g: Function<B, C?>,
        _ h: Function<C, D?>,
        _ i: Function<D, E?>,
        _ j: Function<E, F?>,
        _ k: Function<F, G?>
    ) -> Function<Input, Output> where Output == G? {
        return f.chained(with: g).chained(with: h).chained(with: i).chained(with: j).chained(with: k)
    }

    /// Creates a pipeline of functions by using the output of each function as the input for the next when not `nil`.
    ///
    /// Chaining is forward composition where the function output is piped forward only when not `nil`.
    /// - Returns: A function that takes the input of the first function and returns the output of the last function,
    ///            or `nil` if any function in the chain returns `nil`.
    public static func chain<B, C, D, E, F, G>(
        _ f: @escaping (Input) -> B?,
        _ g: @escaping (B) -> C?,
        _ h: @escaping (C) -> D?,
        _ i: @escaping (D) -> E?,
        _ j: @escaping (E) -> F?,
        _ k: @escaping (F) -> G?
    ) -> Function<Input, Output> where Output == G? {
        return promote(f).chained(with: g).chained(with: h).chained(with: i).chained(with: j).chained(with: k)
    }
}

// MARK: - Backward Composition

extension Function {
    /// Returns a new function that pipes the output of the given function into this function.
    ///
    /// This operation is known as backward function composition.
    /// - Parameter other: The function with which to compose.
    /// - Returns: A new function that pipes the output of the given function into this function.
    public func composed<A>(with other: Function<A, Input>) -> Function<A, Output> {
        return composed(with: other.apply)
    }

    /// Returns a new function that pipes the output of the given function into this function.
    ///
    /// This operation is known as backward function composition.
    /// - Parameter other: The function with which to compose.
    /// - Returns: A new function that pipes the output of the given function into this function.
    public func composed<A>(with other: @escaping (A) -> Input) -> Function<A, Output> {
        return .init { a in
            self.apply(other(a))
        }
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B>(
        _ f: Function<B, Output>,
        _ g: Function<Input, B>
    ) -> Function<Input, Output> {
        return f.composed(with: g)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B>(
        _ f: @escaping (B) -> Output,
        _ g: @escaping (Input) -> B
    ) -> Function<Input, Output> {
        return promote(f).composed(with: g)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C>(
        _ f: Function<C, Output>,
        _ g: Function<B, C>,
        _ h: Function<Input, B>
    ) -> Function<Input, Output> {
        return f.composed(with: g).composed(with: h)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C>(
        _ f: @escaping (C) -> Output,
        _ g: @escaping (B) -> C,
        _ h: @escaping (Input) -> B
    ) -> Function<Input, Output> {
        return promote(f).composed(with: g).composed(with: h)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D>(
        _ f: Function<D, Output>,
        _ g: Function<C, D>,
        _ h: Function<B, C>,
        _ i: Function<Input, B>
    ) -> Function<Input, Output> {
        return f.composed(with: g).composed(with: h).composed(with: i)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D>(
        _ f: @escaping (D) -> Output,
        _ g: @escaping (C) -> D,
        _ h: @escaping (B) -> C,
        _ i: @escaping (Input) -> B
    ) -> Function<Input, Output> {
        return promote(f).composed(with: g).composed(with: h).composed(with: i)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D, E>(
        _ f: Function<E, Output>,
        _ g: Function<D, E>,
        _ h: Function<C, D>,
        _ i: Function<B, C>,
        _ j: Function<Input, B>
    ) -> Function<Input, Output> {
        return f.composed(with: g).composed(with: h).composed(with: i).composed(with: j)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D, E>(
        _ f: @escaping (E) -> Output,
        _ g: @escaping (D) -> E,
        _ h: @escaping (C) -> D,
        _ i: @escaping (B) -> C,
        _ j: @escaping (Input) -> B
    ) -> Function<Input, Output> {
        return promote(f).composed(with: g).composed(with: h).composed(with: i).composed(with: j)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D, E, F>(
        _ f: Function<F, Output>,
        _ g: Function<E, F>,
        _ h: Function<D, E>,
        _ i: Function<C, D>,
        _ j: Function<B, C>,
        _ k: Function<Input, B>
    ) -> Function<Input, Output> {
        return f.composed(with: g).composed(with: h).composed(with: i).composed(with: j).composed(with: k)
    }

    /// Creates a composition of functions by piping the output of each function into the previous.
    ///
    /// This operation is known as backward function composition.
    /// - Returns: A function that takes the input of the last function and returns the output of the first function.
    public static func composition<B, C, D, E, F>(
        _ f: @escaping (F) -> Output,
        _ g: @escaping (E) -> F,
        _ h: @escaping (D) -> E,
        _ i: @escaping (C) -> D,
        _ j: @escaping (B) -> C,
        _ k: @escaping (Input) -> B
    ) -> Function<Input, Output> {
        return promote(f).composed(with: g).composed(with: h).composed(with: i).composed(with: j).composed(with: k)
    }
}

// MARK: - Currying

/// A function of shape `(A) -> (B) -> C`.
///
/// This type can be viewed as a two argument function with its arguments separated to allow for partial application.
public typealias CurriedTwoArgumentFunction<A, B, C> = Function<A, Function<B, C>>

/// A function of shape `(A) -> (B) -> (C) -> D`.
///
/// This type can be viewed as a three argument function with its arguments separated to allow for partial application.
public typealias CurriedThreeArgumentFunction<A, B, C, D> = Function<A, Function<B, Function<C, D>>>

/// A function of shape `(A) -> (B) -> (C) -> (D) -> E`.
///
/// This type can be viewed as a four argument function with its arguments separated to allow for partial application.
public typealias CurriedFourArgumentFunction<A, B, C, D, E> = Function<A, Function<B, Function<C, Function<D, E>>>>

/// A function of shape `(A) -> (B) -> (C) -> (D) -> (E) -> F`.
///
/// This type can be viewed as a five argument function with its arguments separated to allow for partial application.
public typealias CurriedFiveArgumentFunction<A, B, C, D, E, F> = Function<A, Function<B, Function<C, Function<D, Function<E, F>>>>>

/// A function of shape `(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> G`.
///
/// This type can be viewed as a six argument function with its arguments separated to allow for partial application.
public typealias CurriedSixArgumentFunction<A, B, C, D, E, F, G> = Function<A, Function<B, Function<C, Function<D, Function<E, Function<F, G>>>>>>

/// A function of shape `(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> H`.
///
/// This type can be viewed as a seven argument function with its arguments separated to allow for partial application.
public typealias CurriedSevenArgumentFunction<A, B, C, D, E, F, G, H> = Function<A, Function<B, Function<C, Function<D, Function<E, Function<F, Function<G, H>>>>>>>

/// A function of shape `(A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> I`.
///
/// This type can be viewed as an eight argument function with its arguments separated to allow for partial application.
public typealias CurriedEightArgumentFunction<A, B, C, D, E, F, G, H, I> = Function<A, Function<B, Function<C, Function<D, Function<E, Function<F, Function<G, Function<H, I>>>>>>>>

extension Function {
    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B) -> C => (A) -> (B) -> C`
    /// - Returns: This function in curried form.
    public func curried<A, B>()
        -> CurriedTwoArgumentFunction<A, B, Output>
        where Input == (A, B) {
            return .init { a in
                .init { b in
                    self.apply((a, b))
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C) -> D => (A) -> (B) -> (C) -> D`
    /// - Returns: This function in curried form.
    public func curried<A, B, C>()
        -> CurriedThreeArgumentFunction<A, B, C, Output>
        where Input == (A, B, C) {
            return .init { a in
                .init { b in
                    .init { c in
                        self.apply((a, b, c))
                    }
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C, D) -> E => (A) -> (B) -> (C) -> (D) -> E`
    /// - Returns: This function in curried form.
    public func curried<A, B, C, D>()
        -> CurriedFourArgumentFunction<A, B, C, D, Output>
        where Input == (A, B, C, D) {
            return .init { a in
                .init { b in
                    .init { c in
                        .init { d in
                            self.apply((a, b, c, d))
                        }
                    }
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C, D, E) -> F => (A) -> (B) -> (C) -> (D) -> (E) -> F`
    /// - Returns: This function in curried form.
    public func curried<A, B, C, D, E>()
        -> CurriedFiveArgumentFunction<A, B, C, D, E, Output>
        where Input == (A, B, C, D, E) {
            return .init { a in
                .init { b in
                    .init { c in
                        .init { d in
                            .init { e in
                                self.apply((a, b, c, d, e))
                            }
                        }
                    }
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C, D, E, F) -> G => (A) -> (B) -> (C) -> (D) -> (E) -> (F) -> G`
    /// - Returns: This function in curried form.
    public func curried<A, B, C, D, E, F>()
        -> CurriedSixArgumentFunction<A, B, C, D, E, F, Output>
        where Input == (A, B, C, D, E, F) {
            return .init { a in
                .init { b in
                    .init { c in
                        .init { d in
                            .init { e in
                                .init { f in
                                    self.apply((a, b, c, d, e, f))
                                }
                            }
                        }
                    }
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C, D, E, F, G) -> H => (A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> H`
    /// - Returns: This function in curried form.
    public func curried<A, B, C, D, E, F, G>()
        -> CurriedSevenArgumentFunction<A, B, C, D, E, F, G, Output>
        where Input == (A, B, C, D, E, F, G) {
            return .init { a in
                .init { b in
                    .init { c in
                        .init { d in
                            .init { e in
                                .init { f in
                                    .init { g in
                                        self.apply((a, b, c, d, e, f, g))
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    /// Returns a new function that outputs a sequence of functions by separating this function's tuple input argument.
    ///
    /// This process of currying can be described as
    ///
    /// `(A, B, C, D, E, F, G, H) -> I => (A) -> (B) -> (C) -> (D) -> (E) -> (F) -> (G) -> (H) -> I`
    /// - Returns: This function in curried form.
    public func curried<A, B, C, D, E, F, G, H>()
        -> CurriedEightArgumentFunction<A, B, C, D, E, F, G, H, Output>
        where Input == (A, B, C, D, E, F, G, H) {
            return .init { a in
                .init { b in
                    .init { c in
                        .init { d in
                            .init { e in
                                .init { f in
                                    .init { g in
                                        .init { h in
                                            self.apply((a, b, c, d, e, f, g, h))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }

    /// Returns a new function that transforms this function from a sequence of functions
    /// to a function that takes in a tuple of two arguments.
    ///
    /// This process of uncurrying can be described as
    ///
    /// `(A) -> (B) -> C => (A, B) -> C`
    /// - Returns: This function with two arguments uncurried.
    /// - Note: Uncurrying is the dual to currying, the process by which a function's tuple of arguments
    ///         is "separated" to create a sequence of functions. See the `curried()` method for more info.
    public func uncurried<B, C>() -> Function<(Input, B), C> where Output == Function<B, C> {
        return .init { input, b in
            self.apply(input).apply(b)
        }
    }

    /// Returns a new function that transforms this function from a sequence of functions
    /// to a function that takes in a tuple of two arguments.
    ///
    /// This process of uncurrying can be described as
    ///
    /// `(A) -> (B) -> C => (A, B) -> C`
    /// - Returns: This function with two arguments uncurried.
    /// - Note: Uncurrying is the dual to currying, the process by which a function's tuple of arguments
    ///         is "separated" to create a sequence of functions. See the `curried()` method for more info.
    public func uncurried<B, C>() -> Function<(Input, B), C> where Output == (B) -> C {
        return promotingOutput().uncurried()
    }
}

// MARK: - Argument Flipping

extension Function {
    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> () -> C => () -> (A) -> C`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<C>()
        -> Function<Void, Function<Input, C>>
        where Output == Function<Void, C> {
            return .init {
                .init { input in
                    self.apply(input).apply(())
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B) -> C => (B) -> (A) -> C`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C>()
        -> Function<B, Function<Input, C>>
        where Output == Function<B, C> {
            return .init { b in
                .init { input in
                    self.apply(input).apply(b)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B) -> C => (B) -> (A) -> C`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C>()
        -> Function<B, Function<Input, C>>
        where Output == (B) -> C {
            return promotingOutput().flippingFirstTwoArguments()
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C) -> D => (B, C) -> (A) -> D`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D>()
        -> Function<(B, C), Function<Input, D>>
        where Output == Function<(B, C), D> {
            return .init { bc in
                .init { input in
                    self.apply(input).apply(bc)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C) -> D => (B, C) -> (A) -> D`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D>()
        -> Function<(B, C), Function<Input, D>>
        where Output == (B, C) -> D {
            return promotingOutput().flippingFirstTwoArguments()
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D) -> E => (B, C, D) -> (A) -> E`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E>()
        -> Function<(B, C, D), Function<Input, E>>
        where Output == Function<(B, C, D), E> {
            return .init { bcd in
                .init { input in
                    self.apply(input).apply(bcd)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D) -> E => (B, C, D) -> (A) -> E`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E>()
        -> Function<(B, C, D), Function<Input, E>>
        where Output == (B, C, D) -> E {
            return promotingOutput().flippingFirstTwoArguments()
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E) -> F => (B, C, D, E) -> (A) -> F`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F>()
        -> Function<(B, C, D, E), Function<Input, F>>
        where Output == Function<(B, C, D, E), F> {
            return .init { bcde in
                .init { input in
                    self.apply(input).apply(bcde)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E) -> F => (B, C, D, E) -> (A) -> F`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F>()
        -> Function<(B, C, D, E), Function<Input, F>>
        where Output == (B, C, D, E) -> F {
            return promotingOutput().flippingFirstTwoArguments()
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E, F) -> G => (B, C, D, E, F) -> (A) -> G`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F, G>()
        -> Function<(B, C, D, E, F), Function<Input, G>>
        where Output == Function<(B, C, D, E, F), G> {
            return .init { bcdef in
                .init { input in
                    self.apply(input).apply(bcdef)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E, F) -> G => (B, C, D, E, F) -> (A) -> G`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F, G>()
        -> Function<(B, C, D, E, F), Function<Input, G>>
        where Output == (B, C, D, E, F) -> G {
            return promotingOutput().flippingFirstTwoArguments()
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E, F, G) -> H => (B, C, D, E, F, G) -> (A) -> G`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F, G, H>()
        -> Function<(B, C, D, E, F, G), Function<Input, H>>
        where Output == Function<(B, C, D, E, F, G), H> {
            return .init { bcdefg in
                .init { input in
                    self.apply(input).apply(bcdefg)
                }
            }
    }

    /// Returns a new curried function with the order of its first two arguments flipped.
    ///
    /// This process of flipping can be described as
    ///
    /// `(A) -> (B, C, D, E, F, G) -> H => (B, C, D, E, F, G) -> (A) -> G`
    /// - Returns: A new curried function with the order of its first two arguments flipped.
    public func flippingFirstTwoArguments<B, C, D, E, F, G, H>()
        -> Function<(B, C, D, E, F, G), Function<Input, H>>
        where Output == (B, C, D, E, F, G) -> H {
            return promotingOutput().flippingFirstTwoArguments()
    }
}

// MARK: - Function Promotion

extension Function {
    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<B>()
        -> Function<Function<Void, B>, Output>
        where Input == () -> B {
            return .init { input in
                self.apply(input.apply)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B>()
        -> Function<Function<A, B>, Output>
        where Input == (A) -> B {
            return .init { input in
                self.apply(input.apply)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B, C>()
        -> Function<Function<(A, B), C>, Output>
        where Input == (A, B) -> C {
            return .init { input in
                // if we don't declare f as a separate variable, we get a compile-time error here
                // TODO: reproduce and file a bug report
                let f = input.apply
                return self.apply(f)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B, C, D>()
        -> Function<Function<(A, B, C), D>, Output>
        where Input == (A, B, C) -> D {
            return .init { input in
                let f = input.apply
                return self.apply(f)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B, C, D, E>()
        -> Function<Function<(A, B, C, D), E>, Output>
        where Input == (A, B, C, D) -> E {
            return .init { input in
                let f = input.apply
                return self.apply(f)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B, C, D, E, F>()
        -> Function<Function<(A, B, C, D, E), F>, Output>
        where Input == (A, B, C, D, E) -> F {
            return .init { input in
                let f = input.apply
                return self.apply(f)
            }
    }

    /// Promotes the input type of a `Function` that takes a Swift function as input.
    /// - Returns: The function with its input type promoted to a `Function`.
    public func promotingInput<A, B, C, D, E, F, G>()
        -> Function<Function<(A, B, C, D, E, F), G>, Output>
        where Input == (A, B, C, D, E, F) -> G {
            return .init { input in
                let f = input.apply
                return self.apply(f)
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<C>()
        -> Function<Input, Function<Void, C>>
        where Output == () -> C {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C>()
        -> Function<Input, Function<B, C>>
        where Output == (B) -> C {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C, D>()
        -> Function<Input, Function<(B, C), D>>
        where Output == (B, C) -> D {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C, D, E>()
        -> Function<Input, Function<(B, C, D), E>>
        where Output == (B, C, D) -> E {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C, D, E, F>()
        -> Function<Input, Function<(B, C, D, E), F>>
        where Output == (B, C, D, E) -> F {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C, D, E, F, G>()
        -> Function<Input, Function<(B, C, D, E, F), G>>
        where Output == (B, C, D, E, F) -> G {
            return .init { input in
                .init(self.apply(input))
            }
    }

    /// Promotes the return type of a `Function` that outputs a Swift function.
    /// - Returns: The function with its return type promoted to a `Function`.
    public func promotingOutput<B, C, D, E, F, G, H>()
        -> Function<Input, Function<(B, C, D, E, F, G), H>>
        where Output == (B, C, D, E, F, G) -> H {
            return .init { input in
                .init(self.apply(input))
            }
    }
}

// MARK: - Function Conversion

extension Function where Input == Output {
    /// Converts this function to its `inout` equivalent by assigning the result of this function to the argument.
    /// - Returns: This function converted to its `inout` equivalent.
    public func toInout() -> InoutFunction<Input> {
        return .init { input in
            input = self.apply(input)
        }
    }
}

// MARK: - Utilities

extension Function {
    /// Calls the function with the given input.
    /// This is a convenience method to call a `Function` taking `Function` input with a Swift function.
    /// - Parameter input: The input with which to call the function.
    /// - Returns: The output of the function.
    public func apply<A, B>(_ input: @escaping (A) -> B) -> Output where Input == Function<A, B> {
        return apply(.init(input))
    }

    /// Calls the function with the given input.
    /// This is a convenience method to call a `Function` taking `InoutFunction` input with a Swift function.
    /// - Parameter input: The input with which to call the function.
    /// - Returns: The output of the function.
    public func apply<A>(_ input: @escaping (inout A) -> Void) -> Output where Input == InoutFunction<A> {
        return apply(.init(input))
    }
}

extension Function {
    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B>(_ a: A, _ b: B) -> Output where Input == (A, B) {
        return apply((a, b))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C>(_ a: A, _ b: B, _ c: C) -> Output where Input == (A, B, C) {
        return apply((a, b, c))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Parameter d: The fourth argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> Output where Input == (A, B, C, D) {
        return apply((a, b, c, d))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Parameter d: The fourth argument to the function.
    /// - Parameter e: The fifth argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C, D, E>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Output where Input == (A, B, C, D, E) {
        return apply((a, b, c, d, e))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Parameter d: The fourth argument to the function.
    /// - Parameter e: The fifth argument to the function.
    /// - Parameter f: The sixth argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C, D, E, F>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Output where Input == (A, B, C, D, E, F) {
        return apply((a, b, c, d, e, f))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Parameter d: The fourth argument to the function.
    /// - Parameter e: The fifth argument to the function.
    /// - Parameter f: The sixth argument to the function.
    /// - Parameter g: The seventh argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C, D, E, F, G>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G) -> Output where Input == (A, B, C, D, E, F, G) {
        return apply((a, b, c, d, e, f, g))
    }

    /// Calls the function with the given input.
    ///
    /// - Parameter a: The first argument to the function.
    /// - Parameter b: The second argument to the function.
    /// - Parameter c: The third argument to the function.
    /// - Parameter d: The fourth argument to the function.
    /// - Parameter e: The fifth argument to the function.
    /// - Parameter f: The sixth argument to the function.
    /// - Parameter g: The seventh argument to the function.
    /// - Parameter h: The eighth argument to the function.
    /// - Returns: The output of the function.
    /// - Note: Referencing this function as a member serves as a method to turn a `Function<Input, Output>`
    ///         back into a Swift function of type `(Input) -> Output`.
    public func apply<A, B, C, D, E, F, G, H>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, _ g: G, _ h: H) -> Output where Input == (A, B, C, D, E, F, G, H) {
        return apply((a, b, c, d, e, f, g, h))
    }
}
