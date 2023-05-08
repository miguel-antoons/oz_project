functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
    Open
    OS
    Property
    System
define
    %%% Pour ouvrir les fichiers
    class TextFile
        from Open.file Open.text
    end

    %%% ? PRESS BUTTON SECTION *

    %%% /!\ Fonction testee /!\
    %%% @pre : les threads sont "ready"
    %%% @post: Fonction appellee lorsqu on appuie sur le bouton de prediction
    %%%        Affiche la prediction la plus probable du prochain mot selon les deux derniers mots entres
    %%% @return: Retourne une liste contenant la liste du/des mot(s) le(s) plus probable(s) accompagnee de 
    %%%          la probabilite/frequence la plus elevee. 
    %%%          La valeur de retour doit prendre la forme:
    %%%                  <return_val> := <most_probable_words> '|' <probability/frequence> '|' nil
    %%%                  <most_probable_words> := <atom> '|' <most_probable_words> 
    %%%                                           | nil
    %%%                  <probability/frequence> := <int> | <float>
    fun {Press}
        WordString Result
    in
        % get word
        {InputText get(1:WordString)}

        case WordString
        of nil then
            {OutputWord set(1:"no word entered")}
        [] _|_ then
            Result = {Search {GetNLast {SentenceToWords WordString} nil MaxNGram 0} Tree.children nil}

            case Result
            of [[nil] 0] then
                {OutputWord set(1:"No prediction was found. Try again...")}
            else
                {OutputWord set(1:Result.1.1)}
            end
        end
        Result
    end

    InputText
    OutputWord
    Tree
    MaxNGram
    FileName

    %%% funtion searches for the most frequently used words following a sequence of words
    fun {Search WordSequence RootChildren PrimitiveResult}
        %%% returns the most frequently used words from a following other words
        fun {GetResult Children Result}
            % if there are no more children
            case Children
            of nil then
                % return the result as is
                Result
            [] H|T then
                % if the result is empty
                case Result
                of nil then
                    % simply add the current word information as the result
                    {GetResult T ({String.toAtom H.word}|nil)|H.freq|nil}
                [] H2|T2 then
                    % if we found a child whose frequency is higher than the current result
                    if T2.1 < H.freq then
                        % replace the result with the current word information
                        {GetResult T ({String.toAtom H.word}|nil)|H.freq|nil}
                    % if we found a child whose frequency is equal to the current result
                    elseif H.freq == T2.1 then
                        % add the current word information to the result
                        {GetResult T {List.append H2 {String.toAtom H.word}|nil}|T2}
                    else
                        {GetResult T Result}
                    end
                end
            end
        end
    in
        case WordSequence
        of nil then
            % if we are at the children of the last inputted word, return the most frequently used words
            {GetResult RootChildren nil}
        [] H|T then
            % if the current word is not in the children
            case RootChildren
            of nil then
                case WordSequence
                of _|T2 then
                    if T2 == nil then
                        case PrimitiveResult
                        of nil then
                            [[nil] 0]
                        [] H2|T2 then
                            PrimitiveResult
                        end
                    else
                        [[nil] 0]
                    end
                end
            [] H2|T2 then
                % if the word searched is equal to the current word
                if H == H2.word then
                    % search the next word in the children of the current word
                    {Search T H2.children nil}
                % verify if the beginning of the two words are the same
                elseif {CompareWordStart H H2.word} then
                    case PrimitiveResult
                    of nil then 
                        % add the word to the primitive result
                        {Search WordSequence T2 ({String.toAtom H2.word}|nil)|H2.freq|nil}
                    [] H3|T3 then
                        % if the frequency of the current word is higher than the current result
                        if H2.freq > T3.1 then
                            % replace the result with the current word information
                            {Search WordSequence T2 ({String.toAtom H2.word}|nil)|H2.freq|nil}
                        elseif H2.freq == T3.1 then
                            % add the current word information to the result
                            {Search WordSequence T2 {List.append H3 {String.toAtom H2.word}|nil}|T3}
                        else
                            {Search WordSequence T2 PrimitiveResult}
                        end
                    end
                else                    
                    {Search WordSequence T2 PrimitiveResult}
                end
            end
        end
    end


    fun {CompareWordStart Word1 Word2}
        if Word1 == nil then
            true
        elseif Word2 == nil then
            false
        else
            if Word1.1 == Word2.1 then
                {CompareWordStart Word1.2 Word2.2}
            else
                false
            end
        end
    end


    %%% ? UTILITIES SECTION *

    fun {ArrayLen Array Len}
        case Array
        of nil then Len
        [] _|T then {ArrayLen T Len+1}
        end
    end


    %%% funtion adds a list to a list of lists
    fun {AppendListOfList LoL L}
        case LoL
        of nil then [L]
        [] H|T then H|{AppendListOfList T L}
        end
    end


    %%% funtion gets last 2 items of a list
    fun {GetNLast List ResultAcc Max Count}
        case List
        of nil then
            ResultAcc
        [] H|T then
            if Count < Max then
                {GetNLast T {Append ResultAcc H|nil} Max Count+1}
            else
                {GetNLast T {Append ResultAcc H|nil}.2 Max Count+1}
            end
        end
    end


    %%% ? PARSE SECTION *

    %%% funtion parses a sentence into a list of words
    fun {SentenceToWords Sentence}
        fun {SentenceToWordsAux S Word Result}
            case S
            of nil then
                if Word == nil orelse {String.toAtom Word} == amp then
                    Result
                else
                    {AppendListOfList Result Word}
                end
            [] H|T then 
                if {Char.isAlNum H} then
                    % Add the character to the word     
                    {SentenceToWordsAux T {List.append Word {Char.toLower H}|nil} Result}
                else
                    % Add the word to the result
                    if {Char.isSpace H} then
                    % Don't add the word if it's empty
                        if Word == nil orelse {String.toAtom Word} == amp then
                        {SentenceToWordsAux T nil Result}
                    else
                        {SentenceToWordsAux T nil {AppendListOfList Result Word}}
                    end
                    elseif {Char.isPunct H} then
                        % Don't add the word if it's empty
                        if Word == nil orelse {String.toAtom Word} == amp then
                            {SentenceToWordsAux T nil Result}
                        else
                            {SentenceToWordsAux T nil {AppendListOfList {AppendListOfList Result Word} {Char.toLower H}|nil}}
                        end
                    else
                        {SentenceToWordsAux T Word Result}
                    end
                end
            end
        end
    in 
        case Sentence
        of nil then nil
        [] _|_ then
            {SentenceToWordsAux Sentence nil nil}
        end
    end

    fun {GetThreeWords List}
        fun {GetThreeWordsAux L Three Result Count PastList}
            case L
            of nil then Result
            [] H|T then
                case PastList
                of nil then Result
                [] _|T2 then
                    if {ArrayLen H 0} == 1 then
                        if {Char.isPunct H.1} then
                            case T 
                            of nil then Result
                            [] _|T3 then 
                                {GetThreeWordsAux T nil Result 0 T3}
                            end
                        else
                            if Count == MaxNGram then
                                {GetThreeWordsAux PastList nil {AppendListOfList Result {AppendListOfList Three H}} 0 T2}
                            else
                                {GetThreeWordsAux T {AppendListOfList Three H} Result Count+1 PastList}
                            end
                        end
                    else
                        if Count == MaxNGram then
                            % Add Three words to the result
                            {GetThreeWordsAux PastList nil {AppendListOfList Result {AppendListOfList Three H}} 0 T2}
                        else
                            % Add word to three words
                            {GetThreeWordsAux T {AppendListOfList Three H} Result Count+1 PastList}
                        end
                    end
                end
            end
        end
    in
        case List
        of nil then nil
        [] _|T then
            {GetThreeWordsAux List nil nil 0 T}
        end
    end

    %%% Thread that parses the lines
    proc {ParseText Lines Port}
        Words List
    in
        case Lines % lines to line
        of nil then skip
        [] H|T then
            List = {SentenceToWords H} % line to words
            Words = {GetThreeWords List}
            for Word in Words do
                {Send Port Word}
            end
            {ParseText T Port}
        end
    end

    %% Thread that parses the lines and sends the result to the port
    proc {ParseThread TextLines Port}
        % if there are no more lines to parse, send a finish message to the port
        case TextLines
        of nil then
            {Send Port finish}
        [] H|T then
            % parse the file text and go to the next text
            {ParseText H Port}
            {ParseThread T Port}
        end
    end
        
    %%% ? READ SECTION *

    %%% funtion reads a file line per line and addds each line at the end of the Tunnel stream
    fun {ReadFile TextFile}
        NextLine
    in
        % read the next line and add it to the return value, then make a
        % recursive call to read the next line if there is one
        {TextFile getS(NextLine)}

        % first, check if there are lines to read
        % {TextFile atEnd(AtEnd)}
        if {Bool.'not' NextLine == false} then
            NextLine|{ReadFile TextFile}
        else
            {TextFile close}
            nil
        end
    end

    %%% Thread that reads the files
    fun {ReadThread Files N ThreadNumber I}
        NewFile NewCustomFile
    in
        case Files
        of nil then nil
        [] H|T then
            if (I mod N) == ThreadNumber then
                % initialise the file objcect and read the file
                NewFile = {New TextFile init(name:{List.append {List.append {GetSentenceFolder} "/"} H})}
                % this appends all the lines of the file to the tunnel, each line will be separated
                if I == 0 andthen {Bool.'not' FileName == nil} then
                    % If a custom file is specified, read it and append it to the tunnel
                    try 
                        NewCustomFile = {New TextFile init(name:FileName)} 
                        {ReadFile NewCustomFile}|{ReadFile NewFile}|{ReadThread T N ThreadNumber I+1}
                    catch _ then 
                        {ReadFile NewFile}|{ReadThread T N ThreadNumber I+1}
                    end
                else
                    {ReadFile NewFile}|{ReadThread T N ThreadNumber I+1}
                end
            else
                {ReadThread T N ThreadNumber I+1}
            end
        end
    end

    %%% ? SAVER THREAD SECTION *

    %%% Function adds a trigram to the tree.
    %%% It does so by taking the first word of the sequence and checking if it is already present in the tree.
    %%% If it is, it increments the frequency of the node and does a recursion to update its children with the next word.
    fun {AddTriGram WordSequence ParentChildren}
        case WordSequence
        of nil then
            % if there are no more words to add to the tree, return nil
            nil
        % if there are still a word to add to the tree
        [] Hw|Tw then
            % check if there are still children to browse
            case ParentChildren
            of nil then
                % if there are none, add a new node from the word and do a recursion
                % to update the children with the remaining words of the sequence
                node(freq:1 word:Hw children:{AddTriGram Tw nil})|nil
            % if there are still children to browse (which means that the searched word could be among thos children)
            [] Hp|Tp then
                % check if the child's word is the same as the searched word
                if Hp.word == Hw then
                    % if it is, increment the frequency of the node and do a recursion to update its children.
                    % Keep the rest of the parent's children as is.
                    node(freq:Hp.freq+1 word:Hp.word children:{AddTriGram Tw Hp.children})|Tp
                else
                    % if it is not, let the current child as is and check if the next child is the searched word
                    Hp|{AddTriGram WordSequence Tp}
                end
            end
        end
    end

    %%% Thread that saves the result of the parsing into a tree
    fun {SaverThread Stream Root N Count}
        NewCount
    in
        % if the stream is empty, return the root and add il to the children to indicate its an array
        case Stream
        of nil then
            Root
        % if there are still elements in the stream, add the trigram to the tree and do a recursion
        % in order to keep the root node updated
        [] H|T then
            % check if a thread has finished
            if H == finish then
                NewCount = Count+1
                % check if all the threads have finished
                if NewCount == N then
                    % if they have, just return the root
                    Root
                else
                    {SaverThread T Root N NewCount}
                end
            else
                {SaverThread T node(freq:Root.freq word:Root.word children:{AddTriGram H Root.children}) N Count}
            end
        end
    end


    %%% ? THREAD LAUNCHING SECTION *

    %%% Funtion launches the reader and parsing thread and creates a stream between them
    proc {LaunchThreadPair Files Port N ThreadNumber}
        Lines % stream that will contain the lines of the files
    in
        thread Lines = {ReadThread Files N ThreadNumber 0} end
        thread {ParseThread Lines Port} end
    end


%%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port N}
        Arg List
    in
        Arg = {GetSentenceFolder}
        List = {OS.getDir Arg}

        for I1 in 0..N-1 do
            {LaunchThreadPair List Port N I1}
        end
    end


    %%% Ajouter vos fonctions et procédures auxiliaires ici %%%

    %%% Fetch Tweets Folder from CLI Arguments
    %%% See the Makefile for an example of how it is called
    fun {GetSentenceFolder}
        Args = {Application.getArgs record('folder'(single type:string optional:false))}
    in
        Args.'folder'
    end

    %%% Decomnentez moi si besoin
    %proc {ListAllFiles L}
    %   case L of nil then skip
    %   [] H|T then {Browse {String.toAtom H}} {ListAllFiles T}
    %   end
    %end
    
    %%% Procedure principale qui cree la fenetre et appelle les differentes procedures et fonctions
    proc {Main}
        %% Fonction d'exemple qui liste tous les fichiers
        %% contenus dans le dossier passe en Argument.
        %% Inspirez vous en pour lire le contenu des fichiers
        %% se trouvant dans le dossier
        %%% N'appelez PAS cette fonction lors de la phase de
        %%% soumission !!!
        % {ListAllFiles {OS.getDir TweetsFolder}}
       
        local
            NbThreads
            OutputText
            Description
            Window
            SeparatedWordsStream
            SeparatedWordsPort
            PressButton
            OpenFile
            Dialog
            Yes
            No
            WindowD
            DialogText
        in
            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
        
            % TODO
            % Creation de l'interface open file
            DialogText = "Voulez-vous ajouter un fichier texte \n pour ameliorer la prediction ?"
            Dialog=td(
                title: "Open File"
                label(text:DialogText width:35 height:5 background:white foreground:black)
                lr(
                    button(text:"Oui" width:15 action:Yes)
                    button(text:"Non" width:15 action:No))
                action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
            )
        
            % Creation de l interface graphique
            Description=td(
                title: "Text predictor"
                lr(
                    text(handle:InputText width:50 height:10 background:white foreground:black wrap:word action:PressButton)
                )
                text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
                action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
            )
            OutputWord = OutputText
            MaxNGram = 3

            % Function that is called upon the predict button press
            proc {PressButton}
                PredictionResult
            in
                {OutputText set(1:"Searching predictions... Please wait.")}
                _ = {Press}
            end
        
             % Creation de la fenetre dialog
            WindowD={QTk.build Dialog}
            {WindowD show}
            
            proc {No}
                {WindowD hide}
                % Creation de la fenetre
                FileName = nil
                Window={QTk.build Description}
                {Window show}
            end

            proc {Yes}
                {WindowD hide}
                
                FileName = {QTk.dialogbox load($)}

                % Creation de la fenetre
                Window={QTk.build Description}
                {Window show}
            end
        
            {InputText tk(insert 'end' "Loading... Please wait.")}
            {InputText bind(event:"<Control-s>" action:PressButton)} % You can also bind events
        
            % On lance les threads de lecture et de parsing
            SeparatedWordsPort = {NewPort SeparatedWordsStream}
            NbThreads = 4
            {LaunchThreads SeparatedWordsPort NbThreads}

            Tree = {SaverThread SeparatedWordsStream node(freq:0 word:0 children:nil) NbThreads 0}

            {InputText set(1:"")}
        end
        %%ENDOFCODE%%
    end
    % Appelle la procedure principale
    {Main}
end