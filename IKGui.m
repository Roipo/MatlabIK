function IKGui
close all;
myGui = gui.autogui('Location','float');
myGui.PanelWidth=200;
set(gcf,'Renderer','OpenGL');

% Always on top
% warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
% jFrame = get(handle(myGui.UiHandle),'JavaFrame'); drawnow;
% jFrame_fHGxClient = jFrame.fHG2Client;
% jFrame_fHGxClient.getWindow.setAlwaysOnTop(true);

fh = figure('WindowKeyPressFcn',@OnKeyPress);

MainAxes=axes('ButtonDownFcn',@OnAxesDown); axis equal;
axis([-2,2,-2,2]);


%% Global variables
axes(MainAxes);
axis([-20,20,-20,20]);
pl = line('Marker','.');

hold on
clickflag = false;

solver=IKSolver;
hLis=addlistener(solver,'IterationDone',@OnSolverIter);

hp = PointSet(solver.X(1:2),'Marker','o');
hLis=addlistener(hp,'PointDragged',@OnPointDragged);

active=false;
%% GUI initialization
BtnInitialize = gui.pushbutton('Initialize');
BtnInitialize.ValueChangedFcn = @OnInitialize;

BtnRandomize = gui.pushbutton('Randomize');
BtnRandomize.ValueChangedFcn = @OnRandomize;

TxtMenuEnergyType = gui.textmenu('Method',{'Gradient','GN'});
TxtMenuEnergyType.Value='Gradient';
TxtMenuEnergyType.ValueChangedFcn = @OnUpdateParams;

sliderTimeStep = gui.intslider('Time step', [0 40]);
sliderTimeStep.ValueChangedFcn = @onSliderEigenNum;

LabelParams = gui.label('');
LabelStatus = gui.label('');

BtnLoadSource = gui.pushbutton('Check something');
BtnLoadSource.ValueChangedFcn = @OnButtonCheckSomething;



%% Callbacks

    function OnInitialize(~)
        
    end
    function OnRandomize(~)
        
    end
    function OnUpdateParams(~)

    end

    function OnAxesDown(src,evtdata)
        modifier = get(gcf,'SelectionType');
        pos=get(gca,'currentpoint'); pos=pos(1,1:2)';
        solver.X = [pos;0];
        switch modifier
            case 'alt'  % in windows this is 'control'
            otherwise
                clickflag = true;
            return;
        end
    end
    function OnKeyPress(src,evtdata)
        switch evtdata.Character
            case 's'
                if active==false
                    active=true;
                    solver.StartInteractive;
                else
                    active=false;
                    solver.StopInteractive;
                end
            case 'i'
                OnInitialize;
            case 'r'
                OnRandomize
        end
        OnUpdateParams;
    end
    function OnPointDragged(src,evtdata)
        solver.X = [hp.X;0];
    end
    function OnSolverIter(src,evtdata)
        LabelStatus.Value = {['IK obj: ', num2str(solver.O)];
                             ['IK grad norm: ', num2str(sum(solver.G.^2))]};
        Redraw;
    end
    function OnButtonCheckSomething(src,evtdata)
        Redraw;
    end
%% Drawing functions
    function Redraw(~)
        P=solver.P;
        pl.XData = P(1,:);
        pl.YData = P(2,:);
        drawnow;
    end
end