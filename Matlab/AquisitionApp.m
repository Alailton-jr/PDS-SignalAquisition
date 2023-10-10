classdef AquisitionApp < matlab.apps.AppBase

    properties (Access = private)
        connected % Flag indicating if the app is connected to the arduíno

        % Parameters of acquired samples
        fs  % Sampling Rate
        points % Number of points per channel
        v_gain % Voltage Gain   
        v_offSet % Voltage Offset
        i_gain % Current Gain
        i_offSet % Current Offset
        Ts 
        Tempo % time Array

        % Serial Connection Parameters
        SerialCon % Serial Connection Object
        boudRate
        databit
        stopbit
    end
    
    % Main funtions
    methods (Access = private)

        % Startup Question before Connecting to the arduino
        function res = CommunicationStartQuestions(app)
            res = true;
            answer = questdlg('Desconecte todos os cabos USB-COM! Continuar?', ... % Espera comando do usuário
            'Conexões USB-COM ', 'Sim','Não','Sim');  % Sim para continuar e não para sair
            switch answer
                case 'Sim'
                    disp(' Reset das interfaces seriais ...')
                case 'Não'
                    disp('Código Encerrado pelo Operador!')
                    res = false;
                return;
            end
            old_objects=instrfind('Type', 'serial');
            if ~isempty(old_objects) 
                fclose(old_objects);
                delete(old_objects);
            end

            answer = questdlg('Conecte o cabo USB PC<->Arduino! Continuar?', ... % Espera comando do usuário
	                    'Conexão PC<->Arduino ', 'Sim','Não','Sim');  % Sim para continuar e não para sair
            switch answer
              case 'Sim'
                  disp(' Configuração da Porta Serial...')
              case 'Não'
                  disp('Código Encerrado pelo Operador!')
                  res = false;
                  return;
            end
        end

        % Read the variable from the TextBox and save it internaly, used to
        % validate the user input and handler any wrong input
        function validarDados(app)
                app.fs = str2double(app.FreqAmostragemEditField.Value);
                app.points = str2double(app.PontosEditField.Value);
                app.boudRate = str2double(app.BaudRateDropDown.Value);
                app.databit = str2double(regexp(app.DataBitDropDown.Value, '\d+', 'match'));
                app.stopbit = str2double(regexp(app.StopBitDropDown.Value, '\d+', 'match'));
                app.v_gain = app.VoltGanhoEditField.Value;
                app.v_offSet = app.VoltOffSetEditField_2.Value; 
                app.i_gain = app.CurGanhoEditField.Value;
                app.i_offSet = app.CurOffSetEditField.Value;
        end

        % Button pushed function: AbrirComunicaoButton
        function AbrirComunicaoButtonPushed(app, event)
            if  ~app.connected
                try
                    % Disconect and Connect the COM port
                    if ~app.CommunicationStartQuestions()
                        return;
                    end
                    app.validarDados() % Update Intern variables
                    ports = serialportlist("all"); % Get all Serial ports
                    if isempty(ports)
                       disp('Nenhuma porta serial Encontrada!');
                       disp('Código encerrado!');
                       return % No Ports Found
                    end
                    Porta_COM=ports{end}; % Get the last Connected port
                    % Open the communication
                    app.SerialCon  = serial(Porta_COM,'BaudRate',app.boudRate,'DataBits',app.databit,'StopBits',app.stopbit);
                    app.SerialCon.InputBufferSize=app.points*2;
                    fopen(app.SerialCon);
                    app.Ts=1/app.fs;
                    app.Tempo= (0:app.Ts:(app.points-1)*app.Ts)';

                    % Change Texts and flags
                    app.AbrirComunicaoButton.Text = "Fechar Comunicação";
                    app.connected = true;
                    app.EnableComponents(false);
                catch % In case any erros Occurs
                    msgbox('Não Foi possível Estabelecer Comunicação');
                    app.connected = false;
                    app.EnableComponents(true);
                    app.AbrirComunicaoButton.Text = "Abrir Comunicação";
                end
            else
                stopasync(app.SerialCon);
                fclose(app.SerialCon);
                delete(app.SerialCon);
                app.AbrirComunicaoButton.Text = "Abrir Comunicação";
                app.connected = false;
                app.EnableComponents(true);
            end
        end
        
        % Button pushed function: AquisitarDadosButton
        function AquisitarDadosButtonPushed(app, event)
            if app.connected
                try
                    app.validarDados();
                    data_s=49; %49=0x32=code ascii('1');
                    fwrite(app.SerialCon,data_s,'uint8'); %Envia '1' para o Arduino disparar a aquisição
                    pause(1);  %pausa de 1 segundo - espera amostragens
                    data_r1 = fread(app.SerialCon,[app.points 1],'uint16');
                    data_r2 = fread(app.SerialCon,[app.points 1],'uint16');
                    Voltage=app.v_gain*data_r1 + app.v_offSet;
                    Current = app.i_gain*data_r2 + app.i_offSet;
                    plot(app.VoltageAxes,app.Tempo', Voltage');
                    plot(app.CurrentAxes,app.Tempo', Current');
                catch
                    msgbox('Não Foi possível Estabelecer Comunicação');
                    stopasync(app.SerialCon);
                    fclose(app.SerialCon);
                    delete(app.SerialCon);
                    app.AbrirComunicaoButton.Text = "Abrir Comunicação";
                    app.connected = false;
                    app.EnableComponents(true);
                end
            end
        end
        
        % Enable and Disable the Connection Params Field
        function EnableComponents(app, boolFlag)
            app.FreqAmostragemEditField.Enable = boolFlag;
            app.PontosEditField.Enable = boolFlag;
            app.BaudRateDropDown.Enable = boolFlag;
            app.DataBitDropDown.Enable = boolFlag;
            app.StopBitDropDown.Enable = boolFlag;
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            if app.connected
                stopasync(app.SerialCon);
                fclose(app.SerialCon);
                delete(app.SerialCon);
            end
            delete(app)
        end

        % Callback function
        function ButtonPushed(app, event)
            % Generate or retrieve data
            x = linspace(0, 10, 100);
            y = sin(x);
    
            % Plot the data on the axes
            plot(app.UIAxes, x, y);
    
            % Customize the plot (optional)
            title(app.UIAxes, 'Sine Wave');
            xlabel(app.UIAxes, 'X-Axis');
            ylabel(app.UIAxes, 'Y-Axis');
        end
    end

    % StartUp Function
    methods (Access = public)
        % Code that executes after component creation, to initialize the
        % variables and centralize the app on screen
        function startupFcn(app)
            % Centralizes the application
            screenSize = get(0, 'ScreenSize');
            appWidth = 800; 
            appHeight = 600;
            xCenter = (screenSize(3) - appWidth) / 2;
            yCenter = (screenSize(4) - appHeight) / 2;
            app.UIFigure.Position(1) = xCenter;
            app.UIFigure.Position(2) = yCenter;
            % initializes internal variables
            app.connected = false;
            app.validarDados();
        end
        function setGainsAndOffSet(app, v_gain, v_offSet, i_gain, i_offSet)
            app.VoltGanhoEditField.Value = v_gain;
            app.VoltOffSetEditField_2.Value = v_offSet;
            app.CurGanhoEditField.Value = i_gain;
            app.CurOffSetEditField.Value = i_offSet;
        end
    end

    % ********************************************************************
    % Auto generated Code for The app creation
    % ********************************************************************

    % Properties that correspond to app components
    properties (Access = private)
        UIFigure                      matlab.ui.Figure
        TabGroup                      matlab.ui.container.TabGroup
        AquisiodeDadosTab             matlab.ui.container.Tab
        AquisitarDadosButton          matlab.ui.control.Button
        AbrirComunicaoButton          matlab.ui.control.Button
        ComunicaoPanel                matlab.ui.container.Panel
        StopBitDropDown               matlab.ui.control.DropDown
        StopBitDropDownLabel          matlab.ui.control.Label
        DataBitDropDown               matlab.ui.control.DropDown
        DataBitDropDownLabel          matlab.ui.control.Label
        BaudRateDropDown              matlab.ui.control.DropDown
        BaudRateDropDownLabel         matlab.ui.control.Label
        PontosEditField               matlab.ui.control.EditField
        PontosEditFieldLabel          matlab.ui.control.Label
        FreqAmostragemEditField       matlab.ui.control.EditField
        FreqAmostragemEditFieldLabel  matlab.ui.control.Label
        TensoPanel_2                  matlab.ui.container.Panel
        VoltGanhoEditField            matlab.ui.control.NumericEditField
        GanhoEditFieldLabel_2         matlab.ui.control.Label
        VoltOffSetEditField_2         matlab.ui.control.NumericEditField
        OffSetEditField_2Label        matlab.ui.control.Label
        CorrentePanel                 matlab.ui.container.Panel
        CurGanhoEditField             matlab.ui.control.NumericEditField
        GanhoEditField_2Label         matlab.ui.control.Label
        CurOffSetEditField            matlab.ui.control.NumericEditField
        OffSetEditFieldLabel          matlab.ui.control.Label
        VoltageAxes                   matlab.ui.control.UIAxes
        CurrentAxes                   matlab.ui.control.UIAxes
        CalibraoTab                   matlab.ui.container.Tab
    end

    % Component initialization
    methods (Access = public)
        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 878 615];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 878 615];

            % Create AquisiodeDadosTab
            app.AquisiodeDadosTab = uitab(app.TabGroup);
            app.AquisiodeDadosTab.Title = 'Aquisição de Dados';

            % Create CurrentAxes
            app.CurrentAxes = uiaxes(app.AquisiodeDadosTab);
            title(app.CurrentAxes, 'Aquisição de Corrente')
            xlabel(app.CurrentAxes, 'Tempo [s]')
            ylabel(app.CurrentAxes, 'Amplitude [A]')
            zlabel(app.CurrentAxes, 'Z')
            app.CurrentAxes.XGrid = 'on';
            app.CurrentAxes.YGrid = 'on';
            app.CurrentAxes.Position = [269 39 584 246];

            % Create VoltageAxes
            app.VoltageAxes = uiaxes(app.AquisiodeDadosTab);
            title(app.VoltageAxes, 'Aquisição de Tensão')
            xlabel(app.VoltageAxes, 'Tempo [s]')
            ylabel(app.VoltageAxes, 'Amplitude [V]')
            zlabel(app.VoltageAxes, 'Z')
            app.VoltageAxes.XGrid = 'on';
            app.VoltageAxes.YGrid = 'on';
            app.VoltageAxes.Position = [269 314 584 246];

            % Create CorrentePanel
            app.CorrentePanel = uipanel(app.AquisiodeDadosTab);
            app.CorrentePanel.Title = 'Corrente';
            app.CorrentePanel.Position = [28 144 210 108];

            % Create OffSetEditFieldLabel
            app.OffSetEditFieldLabel = uilabel(app.CorrentePanel);
            app.OffSetEditFieldLabel.HorizontalAlignment = 'right';
            app.OffSetEditFieldLabel.Position = [24 21 39 22];
            app.OffSetEditFieldLabel.Text = 'OffSet';

            % Create CurOffSetEditField
            app.CurOffSetEditField = uieditfield(app.CorrentePanel, 'numeric');
            app.CurOffSetEditField.Position = [78 21 111 22];

            % Create GanhoEditField_2Label
            app.GanhoEditField_2Label = uilabel(app.CorrentePanel);
            app.GanhoEditField_2Label.HorizontalAlignment = 'right';
            app.GanhoEditField_2Label.Position = [24 54 42 22];
            app.GanhoEditField_2Label.Text = 'Ganho';

            % Create CurGanhoEditField
            app.CurGanhoEditField = uieditfield(app.CorrentePanel, 'numeric');
            app.CurGanhoEditField.Position = [81 54 105 22];
            app.CurGanhoEditField.Value = 1;

            % Create TensoPanel_2
            app.TensoPanel_2 = uipanel(app.AquisiodeDadosTab);
            app.TensoPanel_2.Title = 'Tensão';
            app.TensoPanel_2.Position = [28 263 210 108];

            % Create OffSetEditField_2Label
            app.OffSetEditField_2Label = uilabel(app.TensoPanel_2);
            app.OffSetEditField_2Label.HorizontalAlignment = 'right';
            app.OffSetEditField_2Label.Position = [24 21 39 22];
            app.OffSetEditField_2Label.Text = 'OffSet';

            % Create VoltOffSetEditField_2
            app.VoltOffSetEditField_2 = uieditfield(app.TensoPanel_2, 'numeric');
            app.VoltOffSetEditField_2.Position = [78 21 111 22];

            % Create GanhoEditFieldLabel_2
            app.GanhoEditFieldLabel_2 = uilabel(app.TensoPanel_2);
            app.GanhoEditFieldLabel_2.HorizontalAlignment = 'right';
            app.GanhoEditFieldLabel_2.Position = [29 51 42 22];
            app.GanhoEditFieldLabel_2.Text = 'Ganho';

            % Create VoltGanhoEditField
            app.VoltGanhoEditField = uieditfield(app.TensoPanel_2, 'numeric');
            app.VoltGanhoEditField.Position = [86 51 103 22];
            app.VoltGanhoEditField.Value = 1;

            % Create ComunicaoPanel
            app.ComunicaoPanel = uipanel(app.AquisiodeDadosTab);
            app.ComunicaoPanel.Title = 'Comunicação';
            app.ComunicaoPanel.Position = [28 380 210 190];

            % Create FreqAmostragemEditFieldLabel
            app.FreqAmostragemEditFieldLabel = uilabel(app.ComunicaoPanel);
            app.FreqAmostragemEditFieldLabel.HorizontalAlignment = 'right';
            app.FreqAmostragemEditFieldLabel.Position = [9 139 104 22];
            app.FreqAmostragemEditFieldLabel.Text = 'Freq. Amostragem';

            % Create FreqAmostragemEditField
            app.FreqAmostragemEditField = uieditfield(app.ComunicaoPanel, 'text');
            app.FreqAmostragemEditField.HorizontalAlignment = 'right';
            app.FreqAmostragemEditField.Position = [128 139 58 22];
            app.FreqAmostragemEditField.Value = '6000';

            % Create PontosEditFieldLabel
            app.PontosEditFieldLabel = uilabel(app.ComunicaoPanel);
            app.PontosEditFieldLabel.HorizontalAlignment = 'right';
            app.PontosEditFieldLabel.Position = [9 109 43 22];
            app.PontosEditFieldLabel.Text = 'Pontos';

            % Create PontosEditField
            app.PontosEditField = uieditfield(app.ComunicaoPanel, 'text');
            app.PontosEditField.HorizontalAlignment = 'right';
            app.PontosEditField.Position = [67 109 119 22];
            app.PontosEditField.Value = '500';

            % Create BaudRateDropDownLabel
            app.BaudRateDropDownLabel = uilabel(app.ComunicaoPanel);
            app.BaudRateDropDownLabel.HorizontalAlignment = 'right';
            app.BaudRateDropDownLabel.Position = [9 75 62 22];
            app.BaudRateDropDownLabel.Text = 'Baud Rate';

            % Create BaudRateDropDown
            app.BaudRateDropDown = uidropdown(app.ComunicaoPanel);
            app.BaudRateDropDown.Items = {'300', '1200', '2400', '4800', '9600', '14400', '19200', '28800', '38400', '57600', '115200', '230400', '250000', '500000', '1000000'};
            app.BaudRateDropDown.Position = [86 75 100 22];
            app.BaudRateDropDown.Value = '115200';

            % Create DataBitDropDownLabel
            app.DataBitDropDownLabel = uilabel(app.ComunicaoPanel);
            app.DataBitDropDownLabel.HorizontalAlignment = 'right';
            app.DataBitDropDownLabel.Position = [9 46 48 22];
            app.DataBitDropDownLabel.Text = 'Data Bit';

            % Create DataBitDropDown
            app.DataBitDropDown = uidropdown(app.ComunicaoPanel);
            app.DataBitDropDown.Items = {'5 bits', '6 bits', '7 bits', '8 bits', '9 bits'};
            app.DataBitDropDown.Position = [72 46 114 22];
            app.DataBitDropDown.Value = '8 bits';

            % Create StopBitDropDownLabel
            app.StopBitDropDownLabel = uilabel(app.ComunicaoPanel);
            app.StopBitDropDownLabel.HorizontalAlignment = 'right';
            app.StopBitDropDownLabel.Position = [9 14 48 22];
            app.StopBitDropDownLabel.Text = 'Stop Bit';

            % Create StopBitDropDown
            app.StopBitDropDown = uidropdown(app.ComunicaoPanel);
            app.StopBitDropDown.Items = {'1 stop bit', '2 stop bits'};
            app.StopBitDropDown.Position = [72 14 114 22];
            app.StopBitDropDown.Value = '1 stop bit';

            % Create AbrirComunicaoButton
            app.AbrirComunicaoButton = uibutton(app.AquisiodeDadosTab, 'push');
            app.AbrirComunicaoButton.ButtonPushedFcn = createCallbackFcn(app, @AbrirComunicaoButtonPushed, true);
            app.AbrirComunicaoButton.Position = [52 101 145 22];
            app.AbrirComunicaoButton.Text = 'Abrir Comunicação';

            % Create AquisitarDadosButton
            app.AquisitarDadosButton = uibutton(app.AquisiodeDadosTab, 'push');
            app.AquisitarDadosButton.ButtonPushedFcn = createCallbackFcn(app, @AquisitarDadosButtonPushed, true);
            app.AquisitarDadosButton.Position = [52 58 145 22];
            app.AquisitarDadosButton.Text = 'Aquisitar Dados';

            % Create CalibraoTab
            app.CalibraoTab = uitab(app.TabGroup);
            app.CalibraoTab.Title = 'Calibração';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    
        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure);
        end
    end
end
