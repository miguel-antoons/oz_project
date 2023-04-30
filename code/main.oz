functor
import 
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    Open
    OS
    Property
    Browser
    % Read at 'file://reading.ozf'
define
    InputWord
    OutputWord

    %%% Pour ouvrir les fichiers
    class TextFile
        from Open.file Open.text
    end

    proc {Browse Buf}
        {Browser.browse Buf}
    end


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
        WordString Word
    in
        % get word
        {InputWord get(1:WordString)}
        % {String.toAtom WordString Word}
        Word = {SeparatedWords2 WordString}
        {Browse Word}
        0
    end

    fun {Append L1 L2}
        case L1
        of nil then L2
        [] H|T then H|{Append T L2}
        else other
        end
    end

    fun {ArrayLen Array Len}
        case Array
        of nil then Len
        [] H|T then {ArrayLen T Len+1}
        end
    end

    %%% funtion reads a file line per line and addds each line at the end of the Tunnel stream
    fun {ReadFile TextFile}
        AtEnd NextLine
    in
        % read the next line and add it to the return value, then make a
        % recursive call to read the next line if there is one
        {TextFile getS(NextLine)}

        % first, check if there are lines to read
        {TextFile atEnd(AtEnd)}
        if AtEnd then
            {TextFile close}
            NextLine|nil
        else
            NextLine|{ReadFile TextFile}
        end
    end

    %%% Thread that reads the files
    fun {ReadThread Files N ThreadNumber I}
        NewFile
    in
        case Files
        of nil then nil
        [] H|T then
            if (I mod N) == ThreadNumber then
                % initialise the file objcect and read the file
                NewFile = {New TextFile init(name:{Append {Append {GetSentenceFolder} "/"} H})}
                % this appends all the lines of the file to the tunnel, each line will be separated
                {ReadFile NewFile}|{ReadThread T N ThreadNumber I+1}
            else
                {ReadThread T N ThreadNumber I+1}
            end
        end
    end

    % List all the words in a sentence
    fun {SeparatedWords2 Sentence}
        fun {AddWord Sentence Acc Result}
            FinalResult
        in 
            case Sentence
            of nil then 
                FinalResult = {String.toAtom {List.reverse Acc}}|Result
                {List.reverse FinalResult}
            [] H|T then
                if {Char.isAlpha H}
                    then {AddWord T H|Acc Result} 
                else
                    {AddWord T nil  {String.toAtom {List.reverse Acc}}|Result} 
                end
            end
        end
    in
        {AddWord Sentence nil nil}
    end

    % List all the words in a sentence
    proc {SeparatedWords Sentence}
        proc {AddWord Sentence Acc Result Count}
            FinalResult Save
        in 
            case Sentence
            of nil then 
                FinalResult = {String.toAtom {List.reverse Acc}}|Result
                {Browse {List.reverse FinalResult}}
            [] H|T then
                if {Char.isAlpha H} then 
                    if {Char.isPunct H} then
                        {AddWord T nil {String.toAtom {List.reverse Acc}}|Result 0} 
                    else
                        {AddWord T {Char.toLower H}|Acc Result Count} 
                    end
                else
                    if {Char.isSpace H} then
                        if Count == 2 then 
                            {AddWord T nil nil 0} 
                            FinalResult = {String.toAtom {List.reverse Acc}}|Result
                            {Browse {List.reverse FinalResult}}
                        else
                            {AddWord T nil {String.toAtom {List.reverse Acc}}|Result Count+1} 
                        end
                    else
                        {AddWord T nil {String.toAtom {List.reverse Acc}}|Result Count} 
                    end
                end
            end
        end
    in
        {AddWord Sentence nil nil 0}
    end

    proc {ParseText Lines}
        List 
    in
        case Lines
        of nil then skip
        [] H|T then
            {SeparatedWords H}
            {Delay 10000}
            {ParseText T}
        end
    end

    %% Thread that parses the lines and sends the result to the port
    proc {ParseThread TextLines Port}
        case TextLines
        of nil then skip
        [] H|T then
            {ParseText H}
        end
        % {ParseText TextLines.1}
        % case Lines
        % of nil then nil
        % [] H|Ts then
        %     % {SeparatedWords H}|{ParseLines T}
        %     {Browse H}
        %     {ParseThread Ts Port}
        % end
    end

    %%% Funtion launches the reader and parsing thread and creates a stream between them
    proc {LaunchThreadPair Files Port N ThreadNumber}
        Lines % stream that will contain the lines of the files
    in
        thread Lines = {ReadThread Files N ThreadNumber 0} end
        thread {ParseThread Lines Port} end
    end

    %%% Function checks if the word is already present in the tree.
    %%% If it is, it returns the node containing the word, else it returns false
    fun {AlreadyInTree Children Word}
        case Children
        of nil then false
        [] H|T then
            if H.word == Word then
                H
            else 
                {AlreadyInTree T Word}
            end
        end
    end


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
    fun {SaverThread Stream Root}
        % if the stream is empty, return the root and add il to the children to indicate its an array
        case Stream
        of nil then
            Root
        % if there are still elements in the stream, add the trigram to the tree and do a recursion
        % in order to keep the root node updated
        [] H|T then
            {SaverThread T node(freq:Root.freq word:Root.word children:{AddTriGram H Root.children})}
        end
    end

    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port Stream N}
        Arg File List Text TextList S1 Tree
    in
        Arg = {GetSentenceFolder}
        List = {OS.getDir Arg}
        {Browse {String.toAtom List.1}}

        for I1 in 0..N do
            {LaunchThreadPair List Port N I1}
        end

        Tree = {SaverThread Stream node(freq:0 word:0 children:nil)}
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
        TweetsFolder = {GetSentenceFolder}
    in
        %% Fonction d'exemple qui liste tous les fichiers
        %% contenus dans le dossier passe en Argument.
        %% Inspirez vous en pour lire le contenu des fichiers
        %% se trouvant dans le dossier
        %%% N'appelez PAS cette fonction lors de la phase de
        %%% soumission !!!
        % {ListAllFiles {OS.getDir TweetsFolder}}
       
        local
            NbThreads
            InputText
            OutputText
            Description
            Window
            SeparatedWordsStream
            SeparatedWordsPort
            PressButton
        in
            {Property.put print foo(width:1000 depth:1000)}  % for stdout siz
        
            % TODO
            {Browse {SaverThread [['salut' 'comment' 'ça'] ['comment' 'ça' 'va'] ['salut' 'ta' 'nathalie']] node(freq:0 word:0 children:nil)}}
        
            % % Creation de l interface graphique
            % Description=td(
            %     title: "Text predictor"
            %     lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:PressButton))
            %     text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
            %     action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
            % )
            % InputWord = InputText

            % % Function that is called upon the predict button press
            % proc {PressButton}
            %     A B C
            % in
            %     {InputText get(A)}
            %     {String.toAtom A C}
            %     {OutputText set(1:C)}
            %     B = {Press}
            % end
        
            % % Creation de la fenetre
            % Window={QTk.build Description}
            % {Window show}
        
            % {InputText tk(insert 'end' "Loading... Please wait.")}
            % {InputText bind(event:"<Control-s>" action:PressButton)} % You can also bind events
        
            % % On lance les threads de lecture et de parsing
            % SeparatedWordsPort = {NewPort SeparatedWordsStream}
            % NbThreads = 1
            % {LaunchThreads SeparatedWordsPort SeparatedWordsStream NbThreads}

            % {InputText set(1:"")}

            % InputWord = InputText
            % OutputWord = OutputText
        end
    end
    % Appelle la procedure principale
    {Main}
end
