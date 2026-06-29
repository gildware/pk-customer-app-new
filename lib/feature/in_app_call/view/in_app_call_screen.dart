import 'package:demandium/util/core_export.dart';
import 'package:get/get.dart';

class InAppCallScreen extends StatelessWidget {
  const InAppCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: GetBuilder<InAppCallController>(builder: (controller) {
            final call = controller.activeCall;
            final peerName = call?.peer.name?.trim().isNotEmpty == true
                ? call!.peer.name!
                : 'unknown'.tr;

            return Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  child: call?.peer.image != null && call!.peer.image!.isNotEmpty
                      ? ClipOval(child: CustomImage(image: call.peer.image, height: 96, width: 96))
                      : Icon(Icons.person, size: 56, color: Theme.of(context).primaryColorLight),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  peerName,
                  style: robotoMedium.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  controller.phaseStatusLabel,
                  style: robotoRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeDefault),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: 32),
                  child: _buildActions(controller),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActions(InAppCallController controller) {
    switch (controller.phase) {
      case InAppCallPhase.incoming:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              icon: Icons.call_end,
              label: 'decline'.tr,
              color: Colors.red,
              onTap: controller.declineIncoming,
            ),
            _actionButton(
              icon: Icons.call,
              label: 'accept'.tr,
              color: Colors.green,
              onTap: controller.acceptIncoming,
            ),
          ],
        );
      case InAppCallPhase.calling:
      case InAppCallPhase.ringing:
        return Center(
          child: _actionButton(
            icon: Icons.call_end,
            label: 'cancel'.tr,
            color: Colors.red,
            onTap: controller.cancelOutgoing,
          ),
        );
      case InAppCallPhase.inCall:
      case InAppCallPhase.connecting:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toggleButton(
                  icon: controller.isMuted ? Icons.mic_off : Icons.mic,
                  label: controller.isMuted ? 'unmute'.tr : 'mute'.tr,
                  active: controller.isMuted,
                  onTap: controller.toggleMute,
                ),
                _toggleButton(
                  icon: controller.isOnHold ? Icons.play_arrow : Icons.pause,
                  label: controller.isOnHold ? 'resume'.tr : 'hold'.tr,
                  active: controller.isOnHold,
                  onTap: controller.toggleHold,
                ),
                _toggleButton(
                  icon: controller.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                  label: 'speaker'.tr,
                  active: controller.isSpeakerOn,
                  onTap: controller.toggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _actionButton(
              icon: Icons.call_end,
              label: 'end_call'.tr,
              color: Colors.red,
              onTap: controller.hangUp,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _toggleButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: active ? Colors.white : Colors.white24,
            child: Icon(icon, color: active ? Colors.black87 : Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: robotoRegular.copyWith(color: Colors.white)),
      ],
    );
  }
}
