"
A small tool to merge exisiting semantics actions in a new Syntax grammar file

use like this:
```st
SyntaxMerger new
	grammarFileLinesFrom: '/path/to/file-without-semantic-actions.semc' ;
	ruleFileLinesFrom: 'path/to/file-with-semantic-actions.semc'' ;
	mergedFilename: '/path/to/merged-file.semc' ;
	merge.
```
"
Class {
	#name : 'SyntaxMerger',
	#superclass : 'Object',
	#instVars : [
		'grammarFileLines',
		'ruleFileLines',
		'mergedStream'
	],
	#category : 'Syntax-merger',
	#package : 'Syntax-merger'
}

{ #category : 'running' }
SyntaxMerger >> completeRule: rule [

	| continuation |

	[ (continuation := grammarFileLines next) endsWith: ';' ]
		whileFalse: [
			rule add: continuation ].
	rule add: continuation.

	^rule
]

{ #category : 'running' }
SyntaxMerger >> findRule: rule [
	"puts #ruleFileLines iterator right after #rule"
	| ruleIterator |
	ruleIterator := rule iterator.

	[ ruleIterator hasNext and: [ruleFileLines hasNext] ]
	whileTrue: [
		(ruleIterator peek = ruleFileLines next)
		ifTrue: [ ruleIterator next ]
		ifFalse: [ ruleIterator := rule iterator ]
	]

	
]

{ #category : 'running' }
SyntaxMerger >> getSemanticAction: lineIterator [
	"#lineIterator is positionned at the start of a semantic action
	 copy the semantic action up to a line with only '}'"

	| actions |
	
	actions := OrderedCollection new.

	[ lineIterator hasNext and: [ lineIterator peek trim ~= '}' ] ]
			whileTrue: [ actions add: lineIterator next ].
	actions add: lineIterator next.

	^actions
]

{ #category : 'accessing' }
SyntaxMerger >> grammarFileLines [

	^ grammarFileLines
]

{ #category : 'accessing' }
SyntaxMerger >> grammarFileLines: anObject [

	grammarFileLines := anObject
]

{ #category : 'accessing' }
SyntaxMerger >> grammarFileLinesFrom: aFileName [
	"#iterator return a decorated iterator that we don't need whereas we need the base iterator
	 to be able to clone it"

	grammarFileLines := aFileName asFileReference
		contents
		lines
		iterator
		decoratedIterator
]

{ #category : 'running' }
SyntaxMerger >> isSemanticAction: aLine ofRule: aRule [
	"extract non terminal of Rule and tries to find it in aLine"

	| firstLine nonTerminal i |
	(aLine first = $$) ifFalse: [ ^false ].

	firstLine := aRule first.
	i := firstLine indexOf: $>.
	(i == 0) ifTrue: [ ^false ].

	nonTerminal := firstLine copyFrom: 1 to: i.
	(aLine includesSubstring: nonTerminal) ifFalse: [ ^false ].

	^true
]

{ #category : 'running' }
SyntaxMerger >> merge [

	| line |
	[
		[ grammarFileLines hasNext ] whileTrue: [
			line := grammarFileLines next.

			(line beginsWith: '<')
				ifFalse: [ self writeLine: line ]
				ifTrue: [ self mergeRule: line ] ]
	] ensure: [	
		mergedStream close
	]
]

{ #category : 'running' }
SyntaxMerger >> merge: ruleFileName into: grammarFileName [

	self ruleFileLinesFrom: ruleFileName.
	self grammarFileLinesFrom: grammarFileName.

	[
		mergedStream := 'merge.semc' asFileReference writeStream.
		
		self merge
	]
	ensure: [
		mergedStream close
	]

]

{ #category : 'running' }
SyntaxMerger >> mergeRule: aLine [

	| rule semanticAction |

	rule := OrderedCollection with: aLine.
	(aLine trim endsWith: ';')
		ifFalse: [ self completeRule: rule ].

	semanticAction := self semanticAction: rule.

	self mergeRule: rule andAction: semanticAction.

	semanticAction ifNotEmpty: [ self skipGrammarSemanticAction: rule ]
]

{ #category : 'running' }
SyntaxMerger >> mergeRule: aRule andAction: semanticActions [

	aRule do: [ :line | self writeLine: line ].
	self writeLine: ''.
	semanticActions do: [ :line | self writeLine: line ].
]

{ #category : 'accessing' }
SyntaxMerger >> mergedFilename: fileName [

	| file |
	file := fileName asFileReference.
	file ensureCreateFile.
	mergedStream := file writeStream
]

{ #category : 'accessing' }
SyntaxMerger >> mergedStream [

	^mergedStream ifNil: [ mergedStream := './mergedGrammar.semc' asFileReference ]
]

{ #category : 'accessing' }
SyntaxMerger >> mergedStream: aWriteStream [

	mergedStream := aWriteStream
]

{ #category : 'accessing' }
SyntaxMerger >> ruleFileLines [

	^ ruleFileLines
]

{ #category : 'accessing' }
SyntaxMerger >> ruleFileLines: anObject [

	ruleFileLines := anObject
]

{ #category : 'accessing' }
SyntaxMerger >> ruleFileLinesFrom: aFileName [
	"#iterator return a decorated iterator that we don't need whereas we need the base iterator
	 to be able to clone it"

	ruleFileLines := aFileName asFileReference
		contents
		lines
		iterator
		decoratedIterator

]

{ #category : 'running' }
SyntaxMerger >> semanticAction: rule [
	"collect all lines in #ruleFileLines composing the semantic action of #rule
	 - put #ruleFileLines right after the #rule
	 - skip blank lines
	 - copy the semantic action of #ruleFileLines in #mergedFile
		(stops at next line with only '}' )"


	| actions |
	self findRule: rule.

	self skipEmptyLines: ruleFileLines.

	(self isSemanticAction: ruleFileLines peek ofRule: rule)
	ifTrue: [ ^self getSemanticAction: ruleFileLines ].

	^#()

]

{ #category : 'running' }
SyntaxMerger >> skipEmptyLines: lineIterator [

	[ lineIterator hasNext and: [ lineIterator peek trim isEmpty ] ]
		whileTrue: [ lineIterator next ]

]

{ #category : 'running' }
SyntaxMerger >> skipGrammarSemanticAction: aRule [
	"if finds a semantic action in #grammarFileLines, skip it"

	self skipEmptyLines: grammarFileLines.

	(grammarFileLines hasNext and: [ self isSemanticAction: grammarFileLines peek ofRule: aRule])
	ifTrue: [
		self getSemanticAction: grammarFileLines
	].

]

{ #category : 'running' }
SyntaxMerger >> writeLine: line [

	^ mergedStream
		  nextPutAll: line;
		  lf
]
