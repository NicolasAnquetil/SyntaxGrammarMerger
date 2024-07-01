"
A SyntaxMergerTest is a test class for testing the behavior of SyntaxMerger
"
Class {
	#name : 'SyntaxMergerTest',
	#superclass : 'TestCase',
	#instVars : [
		'merger',
		'mergedFile'
	],
	#category : 'Syntax-merger',
	#package : 'Syntax-merger'
}

{ #category : 'tests' }
SyntaxMergerTest >> grammarFile: lines [

	merger grammarFileLines: lines iterator.
]

{ #category : 'tests' }
SyntaxMergerTest >> grammarRawFile: contents [

	self grammarFile: contents lines.
]

{ #category : 'tests' }
SyntaxMergerTest >> ruleFile: lines [

	merger ruleFileLines: lines iterator.
]

{ #category : 'tests' }
SyntaxMergerTest >> ruleRawFile: contents [

	self ruleFile: contents lines.
]

{ #category : 'running' }
SyntaxMergerTest >> setUp [
	| dir |
	super setUp.

	merger := SyntaxMerger new.
	
	dir := FileSystem memory workingDirectory / 'tests.dir'.
	dir createDirectory.
	mergedFile:= dir / 'merged.semc'.
	mergedFile createFile.

	merger mergedStream: mergedFile writeStream
]

{ #category : 'tests' }
SyntaxMergerTest >> testCompleteRule [
	| merged |

	self grammarFile: #( 'line2' 'line3;' ).

	self assert: merger grammarFileLines hasNext.

	merged := merger completeRule: (OrderedCollection with: 'line1').

	self
		assertCollection: merged
		equals: (OrderedCollection withAll: #('line1' 'line2' 'line3;') ).

	self deny: merger grammarFileLines hasNext.

]

{ #category : 'tests' }
SyntaxMergerTest >> testFindRule [

	self ruleFile: #( 'line1' 'line2' 'line3' ).

	self assert: merger ruleFileLines peek equals: 'line1'.

	merger findRule: (OrderedCollection with: 'line1').

	self assert: merger ruleFileLines peek equals: 'line2'.

	
]

{ #category : 'tests' }
SyntaxMergerTest >> testFindRule2Lines [

	self ruleFile: #( 'line1' 'line2' 'line3' ).

	self assert: merger ruleFileLines peek equals: 'line1'.

	merger findRule: (OrderedCollection withAll: #('line1' 'line2')).

	self assert: merger ruleFileLines peek equals: 'line3'.

	
]

{ #category : 'tests' }
SyntaxMergerTest >> testFindRuleBacktrack [

	self ruleFile: #( 'line1' 'line2' 'line1' 'line3' 'line4').

	self assert: merger ruleFileLines peek equals: 'line1'.

	merger findRule: (OrderedCollection withAll: #('line1' 'line3')).

	self assert: merger ruleFileLines peek equals: 'line4'.

	
]

{ #category : 'tests' }
SyntaxMergerTest >> testFindRuleNotFound [

	self ruleFile: #( 'line1' 'line2' 'line3' ).

	self assert: merger ruleFileLines peek equals: 'line1'.

	merger findRule: (OrderedCollection with: 'line4').

	self deny: merger ruleFileLines hasNext

	
]

{ #category : 'tests' }
SyntaxMergerTest >> testGetSemanticAction [

	| source actual |
	source := #( '$(<line1>) = {' '}' 'line3' ) iterator.

	self assert: source peek equals: '$(<line1>) = {'.

	actual := merger getSemanticAction: source.

	self assert: source peek equals: 'line3'.

	self assertCollection: actual asArray equals: #( '$(<line1>) = {' '}' )

]

{ #category : 'tests' }
SyntaxMergerTest >> testIsSemanticActionOfRule [

	| rule |
	rule := #('<99:non-terminal>' '= blah;').

	self deny: (merger isSemanticAction: 'blah = nothing' ofRule: rule).
	self deny: (merger isSemanticAction: '$(blah) = nothing' ofRule: rule).
	self deny: (merger isSemanticAction: '<99:non-terminal> = nothing' ofRule: rule).

	self assert: (merger isSemanticAction: '$(<99:non-terminal>) = nothing' ofRule: rule).
]

{ #category : 'tests' }
SyntaxMergerTest >> testMerge [
	| expected |

	self grammarFile: #( 'line1' 'line2' 'line3' ).

	self assert: merger grammarFileLines hasNext.

	merger merge.
	merger mergedStream close.

	expected := Character lf join: #('line1' 'line2' 'line3' '').
	self assert: mergedFile contents equals: expected.

	self deny: merger grammarFileLines hasNext.

]

{ #category : 'tests' }
SyntaxMergerTest >> testMergeRule [
	"rule to match is the first in ruleFile"
	| expected |

	self grammarRawFile: '		= <2:main_program> %EOL ;'.

	self ruleRawFile: '* An executable program must contain one and only one main program.
* An executable program may contain external procedures specified
* by means other than FORTAN.

<1:executable_program>
		= <2:main_program> %EOL ;

$LIST(<1:executable_program>)
{
  $LIST(<1:executable_program>) = $LIST(<2:main_program>);
}
	
*------------------------------------------------------------------------------

<1:executable_program>
		= <3:function_subprogram> %EOL ;

$LIST(<1:executable_program>)
{
  $LIST(<1:executable_program>) = $LIST(<3:function_subprogram>);
}
'.

	merger mergeRule: '<1:executable_program>'.
	merger mergedStream close.

	expected := Character lf join: #( '<1:executable_program>'
'		= <2:main_program> %EOL ;'
''
'$LIST(<1:executable_program>)'
'{'
'  $LIST(<1:executable_program>) = $LIST(<2:main_program>);'
'}'
'').
	self assert: mergedFile contents equals: expected.

]

{ #category : 'tests' }
SyntaxMergerTest >> testMergeRule2ndRule [
	"rule to match is the second in ruleFile"
	| expected |

	self grammarRawFile: '		= <3:function_subprogram> %EOL ;
'.

	self ruleRawFile: '* An executable program must contain one and only one main program.

<1:executable_program>
		= <2:main_program> %EOL ;

$LIST(<1:executable_program>)
{
  $LIST(<1:executable_program>) = $LIST(<2:main_program>);
}
	
*------------------------------------------------------------------------------

<1:executable_program>
		= <3:function_subprogram> %EOL ;

$LIST(<1:executable_program>)
{
  $LIST(<1:executable_program>) = $LIST(<3:function_subprogram>);
}
'.

	merger mergeRule: '<1:executable_program>'.
	merger mergedStream close.

	expected := Character lf join: #( '<1:executable_program>'
'		= <3:function_subprogram> %EOL ;'
''
'$LIST(<1:executable_program>)'
'{'
'  $LIST(<1:executable_program>) = $LIST(<3:function_subprogram>);'
'}'
'').
	self assert: mergedFile contents equals: expected.

]

{ #category : 'tests' }
SyntaxMergerTest >> testMergeRuleAndAction [

	| expected |
	merger mergeRule: #( 'line1' ) andAction: #( 'line2' 'line3').
	merger mergedStream close.

	expected := Character lf join: #('line1' '' 'line2' 'line3' '').
	self assert: mergedFile contents equals: expected
]

{ #category : 'tests' }
SyntaxMergerTest >> testSemanticAction [

	| actual |
	self ruleFile: #( '<line1>' '' '$(<line1>) = {' '}' 'line3' ).

	self assert: merger ruleFileLines peek equals: '<line1>'.

	actual := merger semanticAction: (OrderedCollection with: '<line1>').

	self assert: merger ruleFileLines peek equals: 'line3'.

	self assertCollection: actual asArray equals: #( '$(<line1>) = {' '}' )

	
]

{ #category : 'tests' }
SyntaxMergerTest >> testSkipEmptyLines [

	| source |
	source := #( '' '' 'line3' ) iterator.

	self assert: source peek equals: ''.

	merger skipEmptyLines: source.

	self assert: source peek equals: 'line3'.

]
