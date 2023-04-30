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
        Word = {SentenceToWords WordString}
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

    fun {AppendListOfList LoL L}
        case LoL
        of nil then [L]
        [] H|T then H|{AppendListOfList T L}
        end
     end

    fun {SentenceToWords Sentence}
        fun {SentenceToWordsAux S Word Result}
            case S
            of nil then Result
            [] H|T then
                if {Char.isAlpha H} then
                    {SentenceToWordsAux T {Append Word {Char.toLower H}|nil} Result}
                else
                    if {Char.isSpace H} then
                        {SentenceToWordsAux T nil {AppendListOfList Result Word}}
                    elseif {Char.isPunct H} then
                        {SentenceToWordsAux T nil {AppendListOfList {AppendListOfList Result Word} {Char.toLower H}|nil}}
                    else
                        {SentenceToWordsAux T Word Result}
                    end
                end
            end
        end
    in 
        case Sentence
        of nil then nil
        [] H|T then
            {SentenceToWordsAux T {Char.toLower H}|nil nil}
        end
    end

    fun {GetThreeWords List}
        fun {GetThreeWordsAux L Three Result Count}
            case L
            of nil then Result
            [] H|T then
                if {ArrayLen H 0} == 1 then
                    if {Char.isPunct H.1} then
                        {GetThreeWordsAux T nil Result 0}
                    else
                        {GetThreeWordsAux T Three Result Count}
                    end
                elseif H == nil then
                    {GetThreeWordsAux T Three Result Count}
                else
                    if Count == 2 then
                        {GetThreeWordsAux T nil {AppendListOfList Three H} 0}
                    else
                        {GetThreeWordsAux T {AppendListOfList Three H} Result Count+1}
                    end
                end
            end
        end
        in
        {GetThreeWordsAux List nil nil 0}
    end

    proc {ParseText Lines Port}
        List Words
    in
        case Lines % lines to line
        of nil then skip
        [] H|T then
            List = {SentenceToWords H}
            Words = {GetThreeWords List}
            {Send Port Words}
            {ParseText T Port}
        end
    end

    %% Thread that parses the lines and sends the result to the port
    proc {ParseThread TextLines Port}
        case TextLines
        of nil then skip
        [] H|T then
            {ParseText H Port}
        end
    end

    %%% Funtion launches the reader and parsing thread and creates a stream between them
    proc {LaunchThreadPair Files Port Stream N ThreadNumber}
        Lines % stream that will contain the lines of the files
    in
        thread Lines = {ReadThread Files N ThreadNumber 0} end
        thread {ParseThread Lines Port} end
        thread {SaverThread Stream} end
    end

    %%% Thread that saves the result of the parsing into a tree
    proc {SaverThread Stream}
        case Stream
        of nil then skip
        [] H|T then
            {Browse H}
            {Delay 1000}
            {SaverThread T}
        end
    end

    %%% Lance les N threads de lecture et de parsing qui liront et traiteront tous les fichiers
    %%% Les threads de parsing envoient leur resultat au port Port
    proc {LaunchThreads Port Stream N}
        Arg File List Text TextList S1
    in
        Arg = {GetSentenceFolder}
        List = {OS.getDir Arg}

        for I1 in 0..N do
            {LaunchThreadPair List Port Stream N I1}
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
        
            % Creation de l interface graphique
            Description=td(
                title: "Text predictor"
                lr(text(handle:InputText width:50 height:10 background:white foreground:black wrap:word) button(text:"Predict" width:15 action:PressButton))
                text(handle:OutputText width:50 height:10 background:black foreground:white glue:w wrap:word)
                action:proc{$}{Application.exit 0} end % quitte le programme quand la fenetre est fermee
            )
            InputWord = InputText

            % Function that is called upon the predict button press
            proc {PressButton}
                A B C
            in
                {InputText get(A)}
                {String.toAtom A C}
                {OutputText set(1:C)}
                B = {Press}
            end
        
            % Creation de la fenetre
            Window={QTk.build Description}
            {Window show}
        
            {InputText tk(insert 'end' "Loading... Please wait.")}
            {InputText bind(event:"<Control-s>" action:PressButton)} % You can also bind events
        
            % On lance les threads de lecture et de parsing
            SeparatedWordsPort = {NewPort SeparatedWordsStream}
            NbThreads = 1
            {LaunchThreads SeparatedWordsPort SeparatedWordsStream NbThreads}

            {InputText set(1:"")}

            InputWord = InputText
            OutputWord = OutputText
        end
    end
    % Appelle la procedure principale
    {Main}
end
